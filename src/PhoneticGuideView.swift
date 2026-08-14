import SwiftUI

@available(macOS 11.0, *)
struct PhoneticGuideView: View {
    let isSmart: Bool

    private var modeName: String { isSmart ? "Smart Phonetic" : "Phonetic" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("\(modeName) Typing", systemImage: "text.cursor")
                        .font(.title2.weight(.semibold))
                    Text("Write Sinhala by typing the sound with familiar Roman letters.")
                        .foregroundColor(.secondary)
                }

                GroupBox("Start with the sound") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type a consonant followed by its vowel sound. The text is composed as you type.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        ExampleGrid(rows: [
                            ("ka", "ක"), ("kaa", "කා"), ("ki", "කි"),
                            ("kee", "කේ"), ("ko", "කො"), ("koo", "කෝ")
                        ])
                    }
                    .padding(.top, 3)
                }

                GroupBox("A few useful patterns") {
                    VStack(alignment: .leading, spacing: 11) {
                        GuidePattern(input: "amma", output: "අම්ම", note: "Type each sound in sequence.")
                        GuidePattern(input: "sh", output: "ශ", note: "Use h after a consonant for common aspirated and combined sounds.")
                        GuidePattern(input: "kri", output: "ක්‍රි", note: "Add r or y after a consonant for joined forms.")
                    }
                    .padding(.top, 3)
                }

                GroupBox("Try these words") {
                    VStack(alignment: .leading, spacing: 11) {
                        GuidePattern(input: "mama", output: "මම", note: "A simple two-syllable word.")
                        GuidePattern(input: "siMhala", output: "සිංහල", note: "Use uppercase M for anusvara; Smart Phonetic also accepts x.")
                        GuidePattern(input: "kramaya", output: "ක්‍රමය", note: "r joins with the preceding consonant.")
                        GuidePattern(input: "priya", output: "ප්‍රිය", note: "A common joined consonant pattern.")
                    }
                    .padding(.top, 3)
                }

                if isSmart {
                    GroupBox("Smart Phonetic shortcuts") {
                        VStack(alignment: .leading, spacing: 11) {
                            GuidePattern(input: "x", output: "ං", note: "A quick shortcut for anusvara.")
                            GuidePattern(input: "q", output: "ද", note: "A quick alternative for da.")
                            GuidePattern(input: "zg", output: "ඟ", note: "Use z before selected sounds for sanyakaya letters.")
                        }
                        .padding(.top, 3)
                    }
                } else {
                    GroupBox("Helpful keys") {
                        VStack(alignment: .leading, spacing: 11) {
                            GuidePattern(input: "M", output: "ං", note: "Use uppercase M for anusvara.")
                            GuidePattern(input: "H", output: "ඃ", note: "Use uppercase H for visarga.")
                        }
                        .padding(.top, 3)
                    }
                }

            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 520, height: isSmart ? 580 : 520)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

@available(macOS 11.0, *)
private struct ExampleGrid: View {
    let rows: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(rows, id: \.0) { input, output in
                HStack(spacing: 7) {
                    Text(input)
                        .font(.system(.body, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(output)
                        .font(.body.weight(.medium))
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 7)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
    }
}

@available(macOS 11.0, *)
private struct GuidePattern: View {
    let input: String
    let output: String
    let note: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(input)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .frame(width: 86, alignment: .leading)
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(output)
                .font(.body.weight(.medium))
                .frame(width: 42, alignment: .leading)
            Text(note)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}
