import Foundation

/// The Smart Phonetic v2 port must reproduce the research repo's reference exactly. The golden file comes
/// from `akshara-phonetics/tools/build_golden.py`; regenerate it when the reference changes. Strings are
/// compared scalar by scalar, as the reference does, not by Swift's canonical equivalence.
///
///     SmartPhoneticV2Tests <repo root>
@main
struct SmartPhoneticV2Tests {
    static var failed = false

    static func same(_ a: String, _ b: String) -> Bool { a.unicodeScalars.elementsEqual(b.unicodeScalars) }

    static func report(_ name: String, _ failures: [String], of total: Int) {
        if failures.isEmpty {
            print("ok   \(name): \(total) rows")
        } else {
            failed = true
            print("FAIL \(name): \(failures.count)/\(total) mismatches")
            failures.prefix(20).forEach { print("     \($0)") }
        }
    }

    static func option(_ name: String) -> SmartPhoneticV2.Options {
        var options = SmartPhoneticV2.Options()
        switch name {
        case "archaic": options.archaic = true
        case "repaya_zwj": options.repayaZwj = true
        case "classical": options.classical = true
        case "rakaransaya_u": options.rakaransayaU = true
        default: fatalError("unknown option \(name)")
        }
        return options
    }

    static func expect(_ name: String, _ actual: String, _ expected: String) {
        if !same(actual, expected) {
            failed = true
            print("FAIL \(name): expected \(expected), got \(actual)")
        }
    }

    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
        let golden = try String(contentsOf: root.appendingPathComponent("tests/smart_phonetic_v2_golden.tsv"), encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
        let started = Date()
        let lexicon = SoundLexicon(SoundLexicon.parse(try String(
            contentsOf: root.appendingPathComponent("support/Resources/sinhala_frequency_model.tsv"), encoding: .utf8)))
        print(String(format: "lexicon: %d words in %.0f ms", lexicon.count.count, Date().timeIntervalSince(started) * 1000))

        func check(_ kind: String, _ name: String, actual: ([String]) -> String, expected: ([String]) -> String) {
            let rows = golden.filter { $0[0] == kind }
            if rows.isEmpty { failed = true; print("FAIL \(name): no \(kind) rows"); return }
            let failures = rows.compactMap { row -> String? in
                let got = actual(row)
                return same(got, expected(row)) ? nil : "\(row.dropFirst().dropLast()): expected \(expected(row)), got \(got)"
            }
            report(name, failures, of: rows.count)
        }

        check("T", "transliteration", actual: { SmartPhoneticV2.transliterate($0[1]) }, expected: { $0[2] })
        check("O", "options", actual: { SmartPhoneticV2.transliterate($0[2], options: option($0[1])) }, expected: { $0[3] })
        check("R", "restyle", actual: { SoundLexicon.restyle($0[2], options: option($0[1])) }, expected: { $0[3] })
        check("K", "sound key", actual: { SoundLexicon.soundKey($0[1]) }, expected: { $0[2] })
        check("N", "normalize", actual: { SoundLexicon.normalize($0[1]) }, expected: { $0[2] })
        check("C", "candidates", actual: {
            lexicon.candidates($0[1], partial: $0[2] == "1").joined(separator: "|")
        }, expected: { $0[3] })
        check("D", "candidates with options", actual: {
            lexicon.candidates($0[2], partial: $0[3] == "1", options: option($0[1])).joined(separator: "|")
        }, expected: { $0[4] })

        // Everyday words and R-07, as in Android's SmartPhoneticV2Test.
        let z = "\u{200D}"
        let words = [
            "lankaava": "ලංකාව", "kruura": "කෲර", "lait": "ලයිට්", "kramaya": "ක්\(z)රමය", "d": "ද්", "D": "ඩ්",
            "ee": "ඒ", "ai": "අයි", "Au": "ඖ", "kaaryaya": "කාර්යය", "dumriya": "දුම්රිය", "henri": "හෙන්රි",
            "dilrukshi": "දිල්රුක්ශි", "mrudu": "මෘදු", "samruddhi": "සමෘද්ධි",
        ]
        for (roman, expected) in words.sorted(by: { $0.key < $1.key }) {
            expect(roman, SmartPhoneticV2.transliterate(roman), expected)
        }
        var classical = SmartPhoneticV2.Options()
        classical.classical = true
        expect("thaamra (classical)", SmartPhoneticV2.transliterate("thaamra", options: classical), "තාම්\(z)ර")
        var styled = SmartPhoneticV2.Options()
        styled.rakaransayaU = true
        styled.repayaZwj = true
        expect("kruura (rakaransaya_u)", SmartPhoneticV2.transliterate("kruura", options: styled), "ක්\(z)රූර")
        expect("karma (repaya_zwj)", SmartPhoneticV2.transliterate("karma", options: styled), "කර්\(z)ම")
        expect("honda", lexicon.candidates("honda").first ?? "", "හොඳ")
        expect("kramaya candidate", lexicon.candidates("kramaya").first ?? "", "ක්\(z)රමය")
        expect("dumriya candidate", lexicon.candidates("dumriya").first ?? "", "දුම්රිය")
        expect("normalize දුම්රිය", SoundLexicon.normalize("දුම්රිය"), "දුම්රිය")
        expect("hasPrefix", lexicon.hasPrefix(SoundLexicon.soundKey("ලංක")) ? "yes" : "no", "yes")

        if failed { exit(1) }
        print("Smart Phonetic v2 tests passed")
    }
}
