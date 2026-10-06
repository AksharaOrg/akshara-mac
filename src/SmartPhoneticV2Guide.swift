import SwiftUI

/// The typing guide for Grammar-correct Smart Phonetic (v2). The Sinhala column is written by the engine
/// itself, with the user's spelling options, so the guide always shows what typing gives. The dictionary
/// examples are what Space picks from the bundled word list (checked by tests/SmartPhoneticV2Tests.swift).
@available(macOS 11.0, *)
struct SmartPhoneticV2Content: View {
    /// "Aa / AA" → the engine's spelling of "Aa".
    private func rows(_ keys: [String]) -> [(String, String)] {
        keys.map { key in
            let first = key.components(separatedBy: " / ")[0]
            return (key, SmartPhoneticService.shared.transliterate(first))
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CollapsibleGuideSection(title: "ස්වර අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("දීර්ඝ ස්වර සඳහා අකුර දෙවරක් යොදන්න. ඇ, ඈ, ඍ, ඓ සහ ඖ සඳහා කැපිටල් අකුරු යොදන්න. ai සහ au ලියැවෙන්නේ අයි සහ අවු ලෙසයි.")
                    ExampleGrid(rows: rows([
                        "a", "aa", "A / ae", "Aa / AA", "i", "ii / I", "u / U", "uu / UU",
                        "R", "e", "ee", "E", "o / O", "oo / OO", "Au / AU", "ai",
                    ]), columns: 2)
                }
            }

            CollapsibleGuideSection(title: "ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("d යනු ද, කැපිටල් D යනු ඩ. මූර්ධජ ණ, ළ සහ ෂ සඳහා කැපිටල් අකුරු යොදන්න.")
                    ExampleGrid(rows: rows([
                        "ka", "ga", "cha", "ja", "ta", "Da", "tha", "da / qa", "na", "Na", "pa", "ba",
                        "ma", "ya", "ra", "la", "La", "wa / va", "sa", "sha", "Sha / Sa", "ha", "fa",
                    ]), columns: 3)
                }
            }

            CollapsibleGuideSection(title: "මහප්‍රාණ අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("අකුරට h එක් කරන්න. ඨ සඳහා T සහ ඪ සඳහා Dh යොදන්න.")
                    ExampleGrid(rows: rows([
                        "kha / Ka", "gha / Ga", "chha", "jha / Ja", "Ta", "Dha", "thha", "dha", "pha / Pa", "bha",
                    ]), columns: 2)
                }
            }

            CollapsibleGuideSection(title: "සඤ්ඤක සහ වෙනත් අක්ෂර") {
                VStack(alignment: .leading, spacing: 12) {
                    note("සඤ්ඤක අකුරු සඳහා z යොදන්න (ඹ සඳහා B). සඤ්ඤක අකුරකින් වචනයක් ආරම්භ නොවේ. ඤ සඳහා zk, ඥ සඳහා zh යොදන්න.")
                    ExampleGrid(rows: rows([
                        "gazga", "kazda", "kazDa", "aBa", "zka", "zha", "aXka",
                    ]), columns: 2)
                }
            }

            CollapsibleGuideSection(title: "පිළි සමඟ ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("ස්වරයක් නැති ව්‍යංජනයකට හල් කිරීම ස්වයංක්‍රීයව යෙදේ. kru ලියැවෙන්නේ කෘ ලෙසයි. ං සඳහා x හෝ M, ඃ සඳහා H යොදන්න.")
                    ExampleGrid(rows: rows([
                        "k", "ka", "kaa", "kA", "kAa", "ki", "kii", "ku", "kuu", "kru / kR", "kruu",
                        "ke", "kee", "kE", "ko", "koo", "kAu", "kax / kaM", "kaH",
                    ]), columns: 2)
                }
            }

            CollapsibleGuideSection(title: "බැඳි අක්ෂර යතුරු කරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("යංශය සහ රකාරාංශය ස්වයංක්‍රීයව යෙදේ. ක, ග වැනි අකුරකට පෙර n ලියූ විට ං ලියැවේ. බැඳි අක්ෂර සඳහා Settings හි Classical conjuncts සක්‍රිය කරන්න.")
                    ExampleGrid(rows: rows([
                        "kya", "kra", "vidyaava", "shrii", "karma", "ganga", "ingriisi", "dumriya",
                    ]), columns: 2)
                }
            }

            CollapsibleGuideSection(title: "ශබ්දකෝෂයෙන් නිවැරදි අක්ෂර වින්‍යාසය") {
                VStack(alignment: .leading, spacing: 12) {
                    note("එක හා සමාන ශබ්ද ඇති අකුරු (න/ණ, ල/ළ, ද/ඩ …) සඳහා Space එබූ විට ශබ්දකෝෂයේ ඇති වචනය යෙදේ. වහාම Backspace එබීමෙන් ඔබ ලියූ ආකාරයටම ලැබේ. වචනය යටින් පෙන්වන යෝජනා 1–5 මගින් හෝ click කිරීමෙන් තෝරාගත හැක.")
                    ExampleGrid(rows: [
                        ("honda ␣", "හොඳ"), ("sinhala ␣", "සිංහල"), ("bada ␣", "බඩ"), ("lamaya ␣", "ළමයා"),
                        ("pilithura ␣", "පිළිතුර"), ("kalu ␣", "කළු"), ("keema ␣", "කෑම"), ("amma ␣", "අම්මා"),
                    ], columns: 2)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}
