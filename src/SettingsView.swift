import SwiftUI
import AppKit

/// The settings shown in the Settings window. Changes apply at once: the input controller reads the same
/// `SmartPhoneticService` and `Preferences`, which save to user defaults.
@available(macOS 11.0, *)
final class SettingsModel: ObservableObject {
    private let phonetic = SmartPhoneticService.shared
    private let preferences = Preferences.shared

    @Published var grammarCorrect = false { didSet { phonetic.enabled = grammarCorrect } }
    @Published var rakaransayaU = false { didSet { phonetic.rakaransayaU = rakaransayaU } }
    @Published var repayaZwj = false { didSet { phonetic.repayaZwj = repayaZwj } }
    @Published var classical = false { didSet { phonetic.classical = classical } }
    @Published var archaic = false { didSet { phonetic.archaic = archaic } }
    @Published var showSuggestions = false { didSet { preferences.showSuggestions = showSuggestions } }
    @Published var doubleSpacePeriod = false { didSet { preferences.doubleSpacePeriod = doubleSpacePeriod } }

    init() { reload() }

    /// Picks up changes made elsewhere (the input menu's Grammar-correct Smart Phonetic).
    func reload() {
        if grammarCorrect != phonetic.enabled { grammarCorrect = phonetic.enabled }
        if rakaransayaU != phonetic.rakaransayaU { rakaransayaU = phonetic.rakaransayaU }
        if repayaZwj != phonetic.repayaZwj { repayaZwj = phonetic.repayaZwj }
        if classical != phonetic.classical { classical = phonetic.classical }
        if archaic != phonetic.archaic { archaic = phonetic.archaic }
        if showSuggestions != preferences.showSuggestions { showSuggestions = preferences.showSuggestions }
        if doubleSpacePeriod != preferences.doubleSpacePeriod { doubleSpacePeriod = preferences.doubleSpacePeriod }
    }
}

@available(macOS 11.0, *)
struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        TabView {
            TypingSettings(model: model)
                .tabItem { Text("Typing") }
            CorrectionSettings(model: model)
                .tabItem { Text("Text Correction") }
            AboutSettings()
                .tabItem { Text("About") }
        }
        .padding(20)
        .frame(width: 560, height: 520)
    }
}

enum AksharaLinks {
    static let github = URL(string: "https://github.com/AksharaOrg/akshara-mac")!
    static let research = URL(string: "https://srilals.github.io/Sinhala-Phonetic-Orthography/")!
    static let researchSource = URL(string: "https://github.com/SrilalS/Sinhala-Phonetic-Orthography")!
    static let romanization = URL(string: "https://srilals.github.io/Sinhala-Phonetic-Orthography/research/phonetic-romanization")!
    static let frequencyList = URL(string: "https://github.com/nlpcuom/Word-Frequency-List-for-Sinhala")!
}

// MARK: - Pages

@available(macOS 11.0, *)
private struct TypingSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        SettingsPage {
            SettingsSection("Smart Phonetic") {
                SettingsToggle(
                    "Grammar-correct Smart Phonetic",
                    "Spells by the rules of Sinhala orthography: d types ද, D types ඩ. Space picks the dictionary "
                        + "spelling (honda → හොඳ); Backspace right after undoes it. Turn off for the classic Smart Phonetic.",
                    isOn: $model.grammarCorrect
                )
                Link("How grammar-correct spelling works", destination: AksharaLinks.romanization)
                    .font(.callout)
            }
            SettingsSection("Spelling Options") {
                SettingsToggle(
                    "Write kruura as ක්‍රූර",
                    "C + r + u as rakaransaya + ු (ක්‍රූර) instead of the usual ෘ / ෲ (කෲර).",
                    isOn: $model.rakaransayaU
                )
                SettingsToggle(
                    "Joined repaya",
                    "karma types කර්‍ම (repaya joined with ZWJ) instead of plain කර්ම.",
                    isOn: $model.repayaZwj
                )
                SettingsToggle(
                    "Classical conjuncts",
                    "Join the 13 bandi akuru pairs with ZWJ: akShara types අක්‍ෂර, ananda types අනන්‍ද.",
                    isOn: $model.classical
                )
                SettingsToggle(
                    "Archaic letters",
                    "Allow ඏ ඐ ෟ ෳ ඎ ඦ and the candrabindu (~n), and + for touching letters (ධම‍්ම).",
                    isOn: $model.archaic
                )
            }
            .disabled(!model.grammarCorrect)
            .opacity(model.grammarCorrect ? 1 : 0.5)
        }
    }
}

@available(macOS 11.0, *)
private struct CorrectionSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        SettingsPage {
            SettingsSection("Suggestions") {
                SettingsToggle(
                    "Show suggestions",
                    "Sound-alike words and completions under the word you type, in Grammar-correct Smart Phonetic. "
                        + "Pick one with 1–5 or a click.",
                    isOn: $model.showSuggestions
                )
            }
            SettingsSection("Punctuation") {
                SettingsToggle("Double-space period", "Two quick spaces insert a period.", isOn: $model.doubleSpacePeriod)
            }
        }
    }
}

@available(macOS 11.0, *)
private struct AboutSettings: View {
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        SettingsPage {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Akshara").font(.title2.weight(.semibold))
                    Text(version).font(.callout).foregroundColor(.secondary)
                    Link("Source code on GitHub", destination: AksharaLinks.github).font(.callout)
                }
            }
            .padding(.bottom, 6)

            SettingsSection("Sinhala Phonetic Orthography") {
                Notice(
                    "Copyright © 2026 Srilal Siriwardhana. Licensed under the MIT License. Grammar-correct Smart "
                        + "Phonetic and the dictionary sound matching are ports of its reference code, and follow its "
                        + "orthographic rules."
                )
                HStack(spacing: 16) {
                    Link("Research site", destination: AksharaLinks.research)
                    Link("Source", destination: AksharaLinks.researchSource)
                }
                .font(.callout)
            }
            SettingsSection("A Word Frequency List for Sinhala") {
                Notice(
                    "The bundled word list is a compact derivative of the University of Moratuwa National Languages "
                        + "Processing Centre word-frequency list. Aloka Fernando and Gihan Dias (2021), “Building a "
                        + "Linguistic Resource: A Word Frequency List for Sinhala,” ICON 2021, pages 606–610."
                )
                Link("Source", destination: AksharaLinks.frequencyList).font(.callout)
            }
            if let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String {
                Notice(copyright)
            }
        }
    }
}

// MARK: - Building blocks

@available(macOS 11.0, *)
private struct SettingsPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
        }
    }
}

@available(macOS 11.0, *)
private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            VStack(alignment: .leading, spacing: 12) { content }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(NSColor.separatorColor), lineWidth: 0.5))
        }
    }
}

@available(macOS 11.0, *)
private struct SettingsToggle: View {
    let title: String
    let summary: String
    @Binding var isOn: Bool

    init(_ title: String, _ summary: String, isOn: Binding<Bool>) {
        self.title = title
        self.summary = summary
        _isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(summary)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(SwitchToggleStyle())
    }
}

@available(macOS 11.0, *)
private struct Notice: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
