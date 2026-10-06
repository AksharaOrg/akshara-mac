import Foundation

/// Sound-alike disambiguation for Smart Phonetic v2: a port of `lexicon.py` from the
/// Sinhala-Phonetic-Orthography research repo. Words are indexed by a sound key that erases the
/// distinctions speakers don't hear or don't write in Latin script (aspiration, ණ/න, ළ/ල, ශ/ෂ/ස,
/// ද/ඩ, vowel length, sanyaka vs cluster …), so "honda" finds හොඳ although the rules spell හොන්ද.
/// Words are returned in the style of the converter options (`restyle`), so a word list in the usual
/// style (කෲර, කර්ම) doesn't undo the user's spelling options (ක්‍රූර, කර්‍ම).
/// A list with no ZWJ at all is repaired with `normalize`; one that has ZWJ is used as written, since
/// `normalize` would also join across word boundaries (බවත්ය).
///
/// Ordering and prefixes work on Unicode scalars, like the reference's Python strings (Swift's own
/// `<` and `hasPrefix` compare graphemes). Words are expected in NFC, as the bundled list is: Swift
/// treats canonically equivalent spellings as one key. Checked against the reference by
/// `tests/SmartPhoneticV2Tests.swift`.
final class SoundLexicon {
    typealias Options = SmartPhoneticV2.Options

    private(set) var count: [String: Int] = [:]
    private var byKey: [String: [String]] = [:]
    private let keys: [[Unicode.Scalar]]
    private let keyStrings: [String]

    init<Rows: Sequence>(_ rows: Rows) where Rows.Element == (String, Int) {
        let list = rows.filter { !$0.0.isEmpty }
        let repair = !list.contains { $0.0.unicodeScalars.contains(SoundLexicon.zwj) }
        for (word, n) in list {
            count[repair ? SoundLexicon.normalize(word) : word, default: 0] += n
        }
        for word in count.keys {
            byKey[SoundLexicon.soundKey(word), default: []].append(word)
        }
        let sorted = byKey.keys.map { Array($0.unicodeScalars) }.sorted { $0.lexicographicallyPrecedes($1) }
        keys = sorted
        keyStrings = sorted.map { String(String.UnicodeScalarView($0)) }
    }

    func exact(_ key: String) -> [String] { byKey[key] ?? [] }

    func prefix(_ key: String, limit: Int = 200) -> [String] {
        let scalars = Array(key.unicodeScalars)
        var out: [String] = []
        var i = firstKeyAtOrAfter(scalars)
        while i < keys.count && keys[i].starts(with: scalars) && out.count < limit {
            out += byKey[keyStrings[i]]!
            i += 1
        }
        return out
    }

    /// True when some word's sound key starts with `key`.
    func hasPrefix(_ key: String) -> Bool {
        let scalars = Array(key.unicodeScalars)
        let i = firstKeyAtOrAfter(scalars)
        return i < keys.count && keys[i].starts(with: scalars)
    }

    /// Ranked Sinhala spellings for a romanized word, or for a word prefix with `partial`.
    func candidates(_ roman: String, limit: Int = 5, partial: Bool = false, options: Options = Options()) -> [String] {
        let spelled = SmartPhoneticV2.transliterate(roman, options: options)
        let key = SoundLexicon.soundKey(spelled)
        if partial {
            // An incomplete word: its last consonant may still take a vowel, so drop a trailing hal.
            let stem = key.unicodeScalars.last == SoundLexicon.hal
                ? String(String.UnicodeScalarView(key.unicodeScalars.dropLast())) : key
            let words = SoundLexicon.unique(prefix(stem)).sorted(by: byFrequency)
            return Array(SoundLexicon.unique(words.map { SoundLexicon.restyle($0, options: options) }).prefix(limit))
        }
        var ranked = SoundLexicon.unique(
            SoundLexicon.unique(exact(key)).sorted(by: byFrequency).map { SoundLexicon.restyle($0, options: options) }
        )
        if SoundLexicon.isExplicit(roman) && (ranked.contains(spelled) || SoundLexicon.isLoneVowel(spelled)) {
            ranked = [spelled] + ranked.filter { $0 != spelled }   // explicit markers beat frequency
        } else if !ranked.contains(spelled) {
            ranked.append(spelled)                                // the rule spelling is always included
        }
        return Array(ranked.prefix(limit))
    }

    private func byFrequency(_ a: String, _ b: String) -> Bool {
        let (ca, cb) = (count[a] ?? 0, count[b] ?? 0)
        return ca != cb ? ca > cb : a.unicodeScalars.lexicographicallyPrecedes(b.unicodeScalars)
    }

    private func firstKeyAtOrAfter(_ key: [Unicode.Scalar]) -> Int {
        var lo = 0
        var hi = keys.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if keys[mid].lexicographicallyPrecedes(key) { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    // MARK: - Spelling functions

    static let hal: Unicode.Scalar = "\u{0DCA}"
    static let zwj: Unicode.Scalar = "\u{200D}"
    private static let ya: Unicode.Scalar = "ය"
    private static let ra: Unicode.Scalar = "ර"

    /// `[ක-ෆ]`: a consonant letter.
    private static func isConsonant(_ c: Unicode.Scalar) -> Bool { (0x0D9A...0x0DC6).contains(c.value) }

    private static func string(_ scalars: [Unicode.Scalar]) -> String { String(String.UnicodeScalarView(scalars)) }

    private static func unique(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    /// C ් ය / C ් ර takes ZWJ, except after ර (G-HC-14, R-09) and C ් ර after ම න ල (R-07).
    private static func joins(_ c: Unicode.Scalar, _ next: Unicode.Scalar) -> Bool {
        c != ra && !(next == ra && "මනල".unicodeScalars.contains(c))
    }

    /// Restores the mandatory ZWJ in yansaya and rakaransaya, for word lists that dropped it.
    static func normalize(_ word: String) -> String {
        let s = Array(word.unicodeScalars)
        var out: [Unicode.Scalar] = []
        out.reserveCapacity(s.count + 2)
        for i in s.indices {
            out.append(s[i])
            // ([ක-ෆ])්(?!ZWJ)(?=([යර]))
            if s[i] == hal, i > 0, isConsonant(s[i - 1]), i + 1 < s.count, s[i + 1] == ya || s[i + 1] == ra,
               joins(s[i - 1], s[i + 1]) {
                out.append(zwj)
            }
        }
        return string(out)
    }

    // Romanization markers that pin down a distinction the sound key erases.
    private static let explicit = try! NSRegularExpression(
        pattern: "[KCGJTDNLPBSWVUIEOAXRMH]|z[a-zA-Z]|aa|ii|uu|ee|oo|ae|thh|dh|kh|gh|chh|jh|ph|bh|x")

    static func isExplicit(_ roman: String) -> Bool {
        explicit.firstMatch(in: roman, range: NSRange(roman.startIndex..., in: roman)) != nil
    }

    /// One independent vowel letter (අ … ඖ). A list has no such words, yet a letter typed on its own is
    /// meant as that letter: frequency would turn ඍ into රු and ඓ into අයි.
    static func isLoneVowel(_ spelling: String) -> Bool {
        let scalars = spelling.unicodeScalars
        return scalars.count == 1 && (0x0D85...0x0D96).contains(scalars.first!.value)
    }

    private static func scalars(_ text: String) -> [Unicode.Scalar] { Array(text.unicodeScalars) }

    private static let foldSequences: [([Unicode.Scalar], [Unicode.Scalar])] = [
        ("ෛ", "යි"), ("ඓ", "අයි"), ("ෞ", "වු"), ("ඖ", "අවු"),
        ("ෘ", "්රු"), ("ෲ", "්රු"), ("ඍ", "රු"), ("ඎ", "රු"),
        ("ඥ", "ග්න"),                                                           // G-NS-12
        ("ඟ", "න්ග"), ("ඦ", "න්ජ"), ("ඬ", "න්ද"), ("ඳ", "න්ද"), ("ඹ", "ම්බ"),   // R-03
        ("ං", "න්"), ("ඞ්", "න්"),                                               // R-11
    ].map { (scalars($0.0), scalars($0.1)) }

    private static let foldChars: [Unicode.Scalar: [Unicode.Scalar]] = {
        let pairs: [(Unicode.Scalar, String)] = [
            ("ඛ", "ක"), ("ඝ", "ග"), ("ඡ", "ච"), ("ඣ", "ජ"), ("ඨ", "ට"), ("ඪ", "ද"), ("ථ", "ත"), ("ධ", "ද"),
            ("ඵ", "ප"), ("භ", "බ"), ("ඩ", "ද"),                                              // G-SP-01, G-SP-06, R-01
            ("ණ", "න"), ("ළ", "ල"), ("ශ", "ස"), ("ෂ", "ස"), ("ඤ", "න"),                        // G-SP-02…05, G-NS-13
            ("ආ", "අ"), ("ඊ", "ඉ"), ("ඌ", "උ"), ("ඒ", "එ"), ("ඕ", "ඔ"), ("ඇ", "එ"), ("ඈ", "එ"),   // G-SP-07, G-TY-04
            ("ා", ""), ("ී", "ි"), ("ූ", "ු"), ("ේ", "ෙ"), ("ෝ", "ො"), ("ැ", "ෙ"), ("ෑ", "ෙ"),
            (zwj, ""),
        ]
        return Dictionary(uniqueKeysWithValues: pairs.map { ($0.0, scalars($0.1)) })
    }()

    /// Replaces every non-overlapping `from`, left to right, like Python's `str.replace`.
    private static func replace(_ s: [Unicode.Scalar], _ from: [Unicode.Scalar], _ to: [Unicode.Scalar]) -> [Unicode.Scalar] {
        guard s.count >= from.count else { return s }
        var out: [Unicode.Scalar] = []
        out.reserveCapacity(s.count + 4)
        var i = 0
        while i < s.count {
            if s[i] == from[0], i + from.count <= s.count, s[i..<(i + from.count)].elementsEqual(from) {
                out += to
                i += from.count
            } else {
                out.append(s[i])
                i += 1
            }
        }
        return out
    }

    static func soundKey(_ text: String) -> String {
        var folded = Array(text.unicodeScalars)
        for (from, to) in foldSequences { folded = replace(folded, from, to) }
        var out: [Unicode.Scalar] = []
        out.reserveCapacity(folded.count)
        for c in folded {
            if let to = foldChars[c] { out += to } else { out.append(c) }
        }
        return string(out)
    }

    /// Writes a word in the style the converter options choose, as `SmartPhoneticV2` would (`restyle()` in
    /// the reference): rakaransaya + u for C + ෘ/ෲ (R-06), ZWJ repaya (R-08), classical bandi akuru (R-10).
    /// With no options the word is unchanged.
    static func restyle(_ word: String, options: Options) -> String {
        guard options.rakaransayaU || options.repayaZwj || options.classical else { return word }
        var s = Array(word.unicodeScalars)
        if options.rakaransayaU {   // ([ක-ෆ])([ෘෲ]) → C ් ZWJ ර ු/ූ, except after ර
            var out: [Unicode.Scalar] = []
            var i = 0
            while i < s.count {
                if isConsonant(s[i]), i + 1 < s.count, s[i + 1] == "ෘ" || s[i + 1] == "ෲ" {
                    out += s[i] == ra ? [s[i], s[i + 1]] : [s[i], hal, zwj, ra, s[i + 1] == "ෘ" ? "ු" : "ූ"]
                    i += 2
                } else {
                    out.append(s[i])
                    i += 1
                }
            }
            s = out
        }
        if options.repayaZwj {   // ර්(?!ZWJ)(?=[ක-ෆ]) → ර් ZWJ
            var out: [Unicode.Scalar] = []
            var i = 0
            while i < s.count {
                if s[i] == ra, i + 2 < s.count, s[i + 1] == hal, isConsonant(s[i + 2]) {
                    out += [ra, hal, zwj]
                    i += 2
                } else {
                    out.append(s[i])
                    i += 1
                }
            }
            s = out
        }
        if options.classical {   // ([ක-ෆ])්(?!ZWJ)(?=([ක-ෆ])) → C ් (ZWJ for the bandi pairs)
            var out: [Unicode.Scalar] = []
            var i = 0
            while i < s.count {
                if isConsonant(s[i]), i + 2 < s.count, s[i + 1] == hal, isConsonant(s[i + 2]) {
                    out += [s[i], hal]
                    if SmartPhoneticV2.bandi.contains(string([s[i], s[i + 2]])) { out.append(zwj) }
                    i += 2
                } else {
                    out.append(s[i])
                    i += 1
                }
            }
            s = out
        }
        return string(s)
    }

    /// Parses "word<TAB>count" lines like the reference: rows whose count isn't a number are skipped.
    static func parse(_ text: String) -> [(String, Int)] {
        var rows: [(String, Int)] = []
        text.enumerateLines { line, _ in
            guard let tab = line.firstIndex(of: "\t"), tab > line.startIndex else { return }
            let n = line[line.index(after: tab)...]
            guard !n.isEmpty, n.allSatisfy({ $0.isASCII && $0.isNumber }), let value = Int(n) else { return }
            rows.append((String(line[..<tab]), value))
        }
        return rows
    }
}
