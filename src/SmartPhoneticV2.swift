import Foundation

/// Smart Phonetic v2: a port of `to_sinhala()` from the Sinhala-Phonetic-Orthography research repo,
/// `src/sinhala_orthography/romanization.py`, with all of its options. The tables mirror the JSON tables
/// in its `data` folder; rule ids refer to its `docs/00-rules.md` and `docs/07-phonetic-romanization.md`.
///
/// Don't change behaviour here first: change the research repo, then port. `tests/SmartPhoneticV2Tests.swift`
/// checks this port against `tests/smart_phonetic_v2_golden.tsv`, generated from the reference by
/// `akshara-phonetics/tools/build_golden.py`. The same golden file holds the Android port.
///
/// Input is read as Unicode scalars, like the reference's Python strings: a Swift `Character` would join a
/// consonant and its vowel sign into one grapheme.
enum SmartPhoneticV2 {
    /// The reference's options, all off by default (`to_sinhala(..., archaic=, repaya_zwj=, classical=, rakaransaya_u=)`).
    struct Options: Equatable {
        /// Allow ඏ ඐ ෟ ෳ ඎ ඁ ඦ and touching letters (R-14).
        var archaic = false
        /// Write repaya as ර්‍ + C instead of plain ර් + C (R-08).
        var repayaZwj = false
        /// ZWJ conjuncts for the classical bandi akuru pairs (R-10), and rakaransaya after ම න ල (R-07).
        var classical = false
        /// Write C + r + u/uu as rakaransaya + ු/ූ (ක්‍රූර) instead of the usual ෘ/ෲ (කෲර) (R-06).
        var rakaransayaU = false
    }

    static let hal = "\u{0DCA}"
    static let zwj = "\u{200D}"
    private static let anusvara = "ං"
    private static let nga = "ඞ"
    private static let sanyaka: Set<String> = ["ඟ", "ඦ", "ඬ", "ඳ", "ඹ"]
    private static let noHal = sanyaka.union(["ළ"])                                   // G-HC-06, G-HC-07
    private static let plain = ["ඟ": "ග", "ඦ": "ජ", "ඬ": "ඩ", "ඳ": "ද", "ඹ": "බ"]      // G-PH-01
    private static let plainBeforeRa: Set<String> = ["ම", "න", "ල"]                    // R-07: දුම්රිය, හෙන්රි
    private static let velars: Set<String> = ["ක", "ඛ", "ග", "ඝ"]                      // R-11
    private static let gaetta = ["u": "ෘ", "uu": "ෲ"]                                  // R-06: C + r + u/uu (G-VS-15)
    /// C-13: ෘ / ෲ only after the consonants where the form is attested (validity.json: valid, loan or rare).
    private static let gaettaAfter: [String: Set<String>] = [
        "u": letters("කගඝජටඩතදධනපබභමවශසහෆ"),
        "uu": letters("කගටඩතදපබම"),
    ]
    private static let front: Set<String> = ["i", "ii", "e", "ee", "ae", "aee", "ai"]
    private static let back: Set<String> = ["u", "uu", "o", "oo", "au"]
    /// G-HC-15, R-10: the classical bandi akuru pairs, as the two letters joined.
    static let bandi: Set<String> = [
        "කෂ", "කව", "ගධ", "ටඨ", "තථ", "තව", "දධ", "දව", "නථ", "නද", "නධ", "නව", "ඤච",
    ]

    private static func letters(_ text: String) -> Set<String> {
        Set(text.unicodeScalars.map { String($0) })
    }

    private enum Token {
        case consonant(letter: String, seq: String)
        case vowel(id: String, independent: String, sign: String)
        /// ං, ඃ or ඁ: needs a vowel base.
        case mark(output: String, seq: String)
        /// "+": touching letters, C ZWJ ් C (archaic).
        case touch
        case literal(Unicode.Scalar)

        var consonantLetter: String? {
            if case let .consonant(letter, _) = self { return letter }
            return nil
        }
        var vowelID: String? {
            if case let .vowel(id, _, _) = self { return id }
            return nil
        }
    }

    // [seq, letter, archaic?]
    private static let consonants: [(String, String, Bool)] = [
        ("k", "ක"), ("c", "ක"), ("kh", "ඛ"), ("K", "ඛ"), ("C", "ඛ"), ("g", "ග"), ("gh", "ඝ"), ("G", "ඝ"),
        ("X", "ඞ"), ("zg", "ඟ"), ("ch", "ච"), ("chh", "ඡ"), ("j", "ජ"), ("jh", "ඣ"), ("J", "ඣ"),
        ("zk", "ඤ"), ("zh", "ඥ"), ("t", "ට"), ("T", "ඨ"), ("D", "ඩ"), ("Dh", "ඪ"), ("N", "ණ"), ("zD", "ඬ"),
        ("th", "ත"), ("thh", "ථ"), ("d", "ද"), ("q", "ද"), ("dh", "ධ"), ("dhh", "ධ"), ("n", "න"),
        ("zd", "ඳ"), ("zdh", "ඳ"), ("zq", "ඳ"), ("p", "ප"), ("ph", "ඵ"), ("P", "ඵ"), ("b", "බ"), ("bh", "භ"),
        ("m", "ම"), ("B", "ඹ"), ("y", "ය"), ("r", "ර"), ("l", "ල"), ("w", "ව"), ("v", "ව"), ("W", "ව"),
        ("V", "ව"), ("sh", "ශ"), ("Sh", "ෂ"), ("S", "ෂ"), ("s", "ස"), ("h", "හ"), ("L", "ළ"), ("f", "ෆ"),
    ].map { ($0.0, $0.1, false) } + [("zj", "ඦ", true)]                                // R-14
    // [seq, id, independent, sign, archaic?]
    private static let vowels: [(String, String, String, String, Bool)] = [
        ("a", "a", "අ", ""), ("aa", "aa", "ආ", "ා"), ("A", "ae", "ඇ", "ැ"),
        ("ae", "ae", "ඇ", "ැ"), ("Aa", "aee", "ඈ", "ෑ"), ("AA", "aee", "ඈ", "ෑ"),
        ("aee", "aee", "ඈ", "ෑ"), ("i", "i", "ඉ", "ි"), ("ii", "ii", "ඊ", "ී"),
        ("I", "ii", "ඊ", "ී"), ("u", "u", "උ", "ු"), ("U", "u", "උ", "ු"),
        ("uu", "uu", "ඌ", "ූ"), ("UU", "uu", "ඌ", "ූ"), ("Uu", "uu", "ඌ", "ූ"),
        ("R", "ru", "ඍ", "ෘ"), ("RR", "ruu", "ඎ", "ෲ"), ("e", "e", "එ", "ෙ"),
        ("ee", "ee", "ඒ", "ේ"), ("E", "ai", "ඓ", "ෛ"), ("o", "o", "ඔ", "ො"),
        ("O", "o", "ඔ", "ො"), ("oo", "oo", "ඕ", "ෝ"), ("OO", "oo", "ඕ", "ෝ"),
        ("Oo", "oo", "ඕ", "ෝ"), ("Au", "au", "ඖ", "ෞ"), ("AU", "au", "ඖ", "ෞ"),
    ].map { ($0.0, $0.1, $0.2, $0.3, false) } + [
        ("~l", "ilu", "ඏ", "ෟ", true), ("~ll", "iluu", "ඐ", "ෳ", true),                 // R-14
    ]
    // [seq, output, archaic?]
    private static let marks: [(String, String, Bool)] = [
        ("x", anusvara, false), ("zn", anusvara, false), ("M", anusvara, false),
        ("H", "ඃ", false), ("~n", "ඁ", true),                                          // R-14, G-NS-06
    ]

    private struct Sequence {
        let scalars: [Unicode.Scalar]
        let token: Token
    }

    /// All sequences for a mode, longest first; ties keep table order (consonants, vowels, marks).
    /// Grouped by first scalar for lookup.
    private static func sequences(archaic: Bool) -> [Unicode.Scalar: [Sequence]] {
        var all: [(String, Token)] = []
        all += consonants.filter { archaic || !$0.2 }.map { ($0.0, Token.consonant(letter: $0.1, seq: $0.0)) }
        all += vowels.filter { archaic || !$0.4 }.map { ($0.0, Token.vowel(id: $0.1, independent: $0.2, sign: $0.3)) }
        all += marks.filter { archaic || !$0.2 }.map { ($0.0, Token.mark(output: $0.1, seq: $0.0)) }
        if archaic { all.append(("+", .touch)) }                                        // R-14, G-HC-17
        let ordered = all.enumerated().sorted {
            let (a, b) = ($0.element.0.unicodeScalars.count, $1.element.0.unicodeScalars.count)
            return a != b ? a > b : $0.offset < $1.offset
        }
        var table: [Unicode.Scalar: [Sequence]] = [:]
        for (_, (seq, token)) in ordered {
            let scalars = Array(seq.unicodeScalars)
            table[scalars[0], default: []].append(Sequence(scalars: scalars, token: token))
        }
        return table
    }

    private static let normalSequences = sequences(archaic: false)
    private static let archaicSequences = sequences(archaic: true)

    private static func tokenize(_ source: [Unicode.Scalar], archaic: Bool) -> [Token] {
        let table = archaic ? archaicSequences : normalSequences
        var tokens: [Token] = []
        tokens.reserveCapacity(source.count)
        var i = 0
        while i < source.count {
            let match = table[source[i]]?.first { seq in
                i + seq.scalars.count <= source.count && source[i..<(i + seq.scalars.count)].elementsEqual(seq.scalars)
            }
            if let match = match {
                tokens.append(match.token)
                i += match.scalars.count
            } else {
                if source[i] != "z" { tokens.append(.literal(source[i])) }   // an unknown z-combination is dropped
                i += 1
            }
        }
        return tokens
    }

    /// G-VS-06: ය after front vowels, ව after back; after a/aa, decided by the next vowel.
    private static func glide(_ previous: String?, _ vowel: String) -> String {
        if let previous = previous, front.contains(previous) { return "ය" }
        if let previous = previous, back.contains(previous) { return "ව" }
        return front.contains(vowel) ? "ය" : "ව"
    }

    private enum State { case vowel, anusvara, hal }

    static func transliterate(_ source: String, options: Options = Options()) -> String {
        let tokens = tokenize(Array(source.unicodeScalars), archaic: options.archaic)
        var out: [String] = []
        out.reserveCapacity(tokens.count * 2)
        var state: State? = nil         // nil: word start
        var previousVowel: String? = nil
        var j = 0
        while j < tokens.count {
            let token = tokens[j]
            let next = j + 1 < tokens.count ? tokens[j + 1] : nil
            let after = j + 2 < tokens.count ? tokens[j + 2] : nil
            switch token {
            case let .consonant(consonantLetter, seq):
                var letter = consonantLetter
                if state == nil, let plainLetter = plain[letter] { letter = plainLetter }
                if letter == nga, next?.vowelID != nil {
                    if state == nil { out.append(seq); j += 1; continue }   // G-PH-01: ඞ never starts a word
                    letter = "ඟ"                                              // G-HC-08: /ŋ/ + vowel is ඟ
                }
                if letter == nga && state == nil { out.append(seq); j += 1; continue }
                // R-11: n + velar after a vowel → ං; word-final "ng" → ං
                if letter == "න", seq == "n", state == .vowel, let nextLetter = next?.consonantLetter, velars.contains(nextLetter) {
                    out.append(anusvara)
                    state = .anusvara
                    var wordFinal = after == nil
                    if case .literal? = after { wordFinal = true }
                    if case let .consonant(_, nextSeq)? = next, nextSeq == "g", wordFinal { j += 2 } else { j += 1 }
                    continue
                }
                out.append(letter)
                switch next {
                case let .vowel(id, _, sign)?:
                    out.append(sign)
                    state = .vowel
                    previousVowel = id
                    j += 2
                case .mark?:
                    state = .vowel                                           // ං/ඃ/ඁ need a vowel base
                    previousVowel = "a"
                    j += 1
                case let .consonant(nextLetter, _)?:
                    if noHal.contains(letter) || sanyaka.contains(nextLetter) {
                        state = .vowel                                       // no hal here: keep inherent a
                        previousVowel = "a"
                        j += 1
                        continue
                    }
                    if letter == nga {
                        out.append(hal)
                    } else if nextLetter == "ය" {
                        out.append(letter != "ර" || options.repayaZwj ? hal + zwj : hal)   // G-HC-11, G-HC-14, R-09
                    } else if nextLetter == "ර" {
                        let vowel = after?.vowelID
                        let ru = vowel.map { gaetta[$0] != nil } ?? false
                        let attested = ru && gaettaAfter[vowel!]!.contains(letter)        // C-13: මෘ, not ලෘ
                        if attested && !options.rakaransayaU {
                            out.append(gaetta[vowel!]!)                                   // G-VS-15, R-06
                            state = .vowel
                            previousVowel = vowel
                            j += 3
                            continue
                        }
                        // R-07: plain hal after ම න ල (දුම්රිය, දිල්රුක්ෂි), except a rakaransaya that stands
                        // for an attested ෘ (rakaransayaU: ම්‍රුදු) or, without u, under classical (තාම්‍ර)
                        let plainHal = letter == "ර" ||
                            (plainBeforeRa.contains(letter) && !attested && !(options.classical && !ru))
                        out.append(plainHal ? hal : hal + zwj)                            // G-HC-12, R-07
                    } else if letter == "ර" {
                        out.append(options.repayaZwj ? hal + zwj : hal)                   // R-08
                    } else if options.classical && bandi.contains(letter + nextLetter) {
                        out.append(hal + zwj)                                             // R-10
                    } else {
                        out.append(hal)
                    }
                    state = .hal
                    j += 1
                case .touch? where after?.consonantLetter != nil && !noHal.contains(letter):
                    out.append(zwj + hal)                                    // R-14: touching letters
                    state = .hal
                    j += 2
                default:                                                     // end of word
                    if noHal.contains(letter) {
                        state = .vowel
                        previousVowel = "a"
                    } else {
                        out.append(hal)
                        state = .hal
                    }
                    j += 1
                }
            case let .vowel(id, independent, sign):
                switch state {
                case .vowel?: out.append(glide(previousVowel, id) + sign)
                case .anusvara?: out[out.count - 1] = "ම" + sign            // G-NS-04: ං never before a vowel
                default: out.append(id == "ruu" && !options.archaic ? "ඍ" : independent)   // G-VS-08: ඎ is archaic
                }
                state = .vowel
                previousVowel = id
                j += 1
            case let .mark(output, seq):
                if output == anusvara, let nextLetter = next?.consonantLetter, sanyaka.contains(nextLetter) {
                    j += 1                                                   // G-NS-09: the sanyaka carries the nasal
                    continue
                }
                if state == .vowel {
                    out.append(output)
                    state = output == anusvara ? .anusvara : .vowel
                } else {
                    out.append(seq)                                          // no base: leave the romanization as written
                    state = nil
                }
                j += 1
            case .touch:
                out.append("+")
                state = nil
                j += 1
            case let .literal(scalar):
                out.append(String(scalar))
                state = nil
                previousVowel = nil
                j += 1
            }
        }
        return out.joined()
    }
}
