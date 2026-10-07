import SwiftUI
import AppKit

/// The settings shown in the Settings window. Changes apply at once: the input controller reads the same
/// `SmartPhoneticService` and `Preferences`, which save to user defaults.
@available(macOS 11.0, *)
final class SettingsModel: ObservableObject {
    private let phonetic = SmartPhoneticService.shared
    private let preferences = Preferences.shared

    @Published var grammarCorrect = false { didSet { phonetic.enabled = grammarCorrect } }
    @Published var retroflexD = false { didSet { phonetic.retroflexD = retroflexD } }
    @Published var rakaransayaU = false { didSet { phonetic.rakaransayaU = rakaransayaU } }
    @Published var repayaZwj = false { didSet { phonetic.repayaZwj = repayaZwj } }
    @Published var classical = false { didSet { phonetic.classical = classical } }
    @Published var archaic = false { didSet { phonetic.archaic = archaic } }
    @Published var showSuggestions = false { didSet { preferences.showSuggestions = showSuggestions } }
    @Published var doubleSpacePeriod = false { didSet { preferences.doubleSpacePeriod = doubleSpacePeriod } }
    /// Whether an Akshara input source is enabled in System Settings.
    @Published private(set) var enabled = false

    init() { reload() }

    /// Picks up changes made elsewhere (the input menu's Grammar-correct Smart Phonetic, System Settings).
    func reload() {
        if grammarCorrect != phonetic.enabled { grammarCorrect = phonetic.enabled }
        if retroflexD != phonetic.retroflexD { retroflexD = phonetic.retroflexD }
        if rakaransayaU != phonetic.rakaransayaU { rakaransayaU = phonetic.rakaransayaU }
        if repayaZwj != phonetic.repayaZwj { repayaZwj = phonetic.repayaZwj }
        if classical != phonetic.classical { classical = phonetic.classical }
        if archaic != phonetic.archaic { archaic = phonetic.archaic }
        if showSuggestions != preferences.showSuggestions { showSuggestions = preferences.showSuggestions }
        if doubleSpacePeriod != preferences.doubleSpacePeriod { doubleSpacePeriod = preferences.doubleSpacePeriod }
        enabled = AksharaSetup.isAksharaEnabled()
    }

    /// Restores every setting to its default, as Android's "Reset keyboard settings" does.
    func reset() {
        grammarCorrect = true
        retroflexD = false
        rakaransayaU = false
        repayaZwj = false
        classical = false
        archaic = false
        showSuggestions = true
        doubleSpacePeriod = true
    }
}

@available(macOS 11.0, *)
struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        TabView {
            GeneralSettings(model: model)
                .tabItem { Text("General") }
            TypingSettings(model: model)
                .tabItem { Text("Typing") }
            CorrectionSettings(model: model)
                .tabItem { Text("Text Correction") }
            AboutSettings(model: model)
                .tabItem { Text("About") }
        }
        .padding(20)
        .frame(width: 600, height: 560)
    }
}

enum AksharaLinks {
    static let github = URL(string: "https://github.com/AksharaOrg/akshara-mac")!
    static let issues = URL(string: "https://github.com/AksharaOrg/akshara-mac/issues")!
    static let research = URL(string: "https://srilals.github.io/Sinhala-Phonetic-Orthography/")!
    static let researchSource = URL(string: "https://github.com/SrilalS/Sinhala-Phonetic-Orthography")!
    static let romanization = URL(string: "https://srilals.github.io/Sinhala-Phonetic-Orthography/research/phonetic-romanization")!
    static let frequencyList = URL(string: "https://github.com/nlpcuom/Word-Frequency-List-for-Sinhala")!
    static let keyboardSettings = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!
}

/// A person shown under About → Contributors: `contributors.json`, shared with the Android app
/// (`akshara-phonetics/tools/sync_word_data.py` copies it).
struct Contributor: Decodable, Hashable {
    let name: String
    let role: String
    let link: String?

    static let all: [Contributor] = {
        guard let url = Bundle.main.url(forResource: "contributors", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Contributor].self, from: data)) ?? []
    }()
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
                    "Spells by the rules of Sinhala orthography. Space picks the dictionary spelling (honda → හොඳ); "
                        + "Backspace right after undoes it. Turn off for the classic Smart Phonetic.",
                    isOn: $model.grammarCorrect
                )
                SettingsToggle(
                    "Type ඩ with d",
                    "On: d types ඩ and dh types ද, as on older Singlish keyboards (D ඪ, Dh ධ). "
                        + "Off: d types ද, dh ධ, D ඩ.",
                    isOn: $model.retroflexD
                )
                .disabled(!model.grammarCorrect)
                .opacity(model.grammarCorrect ? 1 : 0.5)
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
private struct GeneralSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        SettingsPage {
            AppHeader(subtitle: model.enabled
                ? "Akshara is enabled. Choose it from the input menu in the menu bar."
                : "Akshara is installed but not enabled yet.")
            if !model.enabled {
                SettingsSection("Get Started") {
                    SettingsButtonRow(
                        "Open Keyboard Settings",
                        "Add Akshara under Input Sources: click +, search for Sinhala and pick an Akshara layout.",
                        systemImage: "keyboard"
                    ) { NSWorkspace.shared.open(AksharaLinks.keyboardSettings) }
                }
            }
            SettingsSection("Guides") {
                SettingsButtonRow("Welcome & Setup Guide", "How to add Akshara and choose a layout.", systemImage: "hand.wave") {
                    WelcomeWindowManager.shared.showWelcomeWindow()
                }
                SettingsButtonRow("Smart Phonetic Typing Guide", "Keys, letters and the dictionary spelling.", systemImage: "character.book.closed") {
                    WelcomeWindowManager.shared.showPhoneticGuideWithSmartMode(true)
                }
                SettingsButtonRow("Phonetic Typing Guide", "The classic romanized layout.", systemImage: "text.cursor") {
                    WelcomeWindowManager.shared.showPhoneticGuideWithSmartMode(false)
                }
            }
            SettingsSection("Updates") {
                SettingsButtonRow("Check for Updates", "Akshara checks GitHub for new releases once a day.",
                                  systemImage: "arrow.triangle.2.circlepath") {
                    AutoUpdater.shared().checkForUpdatesManually()
                }
            }
        }
        .onAppear { model.reload() }
    }
}

@available(macOS 11.0, *)
private struct AboutSettings: View {
    @ObservedObject var model: SettingsModel
    @State private var showingPrivacy = false
    @State private var showingNotices = false
    @State private var confirmingReset = false

    private var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

    var body: some View {
        SettingsPage {
            AppHeader(subtitle: "Made in Sri Lanka by the Akshara contributors.")
            SettingsSection(nil) {
                SettingsRow("Version", info["CFBundleShortVersionString"] as? String ?? "?")
                SettingsRow("Build", info["CFBundleVersion"] as? String ?? "?")
            }
            SettingsSection("People") {
                ForEach(Contributor.all, id: \.self) { person in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                            Text(person.role).font(.callout).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        if let link = person.link.flatMap(URL.init(string:)) {
                            Link("Profile", destination: link).font(.callout)
                        }
                    }
                }
                Text("Akshara is open source, and more people are welcome to join. Thank you also to everyone who "
                     + "reports issues, tests builds and shares feedback.")
                    .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                SettingsButtonRow("Contribute on GitHub", "Report issues, suggest words or send a pull request.",
                                  systemImage: "chevron.left.forwardslash.chevron.right") {
                    NSWorkspace.shared.open(AksharaLinks.github)
                }
            }
            SettingsSection("Legal") {
                SettingsButtonRow("Privacy Policy", "Typing stays on this Mac.", systemImage: "hand.raised") {
                    showingPrivacy = true
                }
                SettingsButtonRow("Open Source Notices", "Spelling research, the word list and their licenses.",
                                  systemImage: "doc.text") {
                    showingNotices = true
                }
                SettingsRow("Copyright", info["NSHumanReadableCopyright"] as? String ?? "")
                SettingsRow("License", "MIT License")
            }
            SettingsSection(nil) {
                SettingsButtonRow("Reset Settings", "Restore typing and correction options to their defaults.",
                                  systemImage: "arrow.counterclockwise", destructive: true) {
                    confirmingReset = true
                }
            }
        }
        .sheet(isPresented: $showingPrivacy) { DocumentSheet(title: "Privacy Policy", sections: Self.privacy) }
        .sheet(isPresented: $showingNotices) { DocumentSheet(title: "Open Source Notices", sections: Self.notices) }
        .alert(isPresented: $confirmingReset) {
            Alert(
                title: Text("Reset Settings"),
                message: Text("This restores typing and correction options to their defaults."),
                primaryButton: .destructive(Text("Reset")) { model.reset() },
                secondaryButton: .cancel()
            )
        }
    }

    /// The Android app's privacy policy, written for macOS.
    static let privacy: [DocumentSection] = [
        DocumentSection("On your Mac", "Typing stays on your Mac. Akshara does not send keystrokes, suggestions or analytics anywhere."),
        DocumentSection("Input method access", "Like every macOS input method, Akshara receives the keys you type while one of its "
            + "input sources is selected, to turn them into Sinhala. It does not store or log them."),
        DocumentSection("Network", "The only network requests are update checks: once a day at most, Akshara asks GitHub for the "
            + "latest akshara-mac release, and it downloads the installer only when you choose to install an update. No typed "
            + "text or personal data is sent."),
        DocumentSection("Predictions", "Word suggestions use a compact word list bundled with the app. Akshara does not learn "
            + "or save what you type."),
        DocumentSection("No tracking", "Akshara has no account, no advertising identifiers, and no third-party analytics or tracking SDKs."),
        DocumentSection("Contact", "Questions and reports: github.com/AksharaOrg/akshara-mac/issues", link: AksharaLinks.issues),
    ]

    static let notices: [DocumentSection] = [
        DocumentSection("Akshara", (Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "")
            + " Source code: github.com/AksharaOrg/akshara-mac", link: AksharaLinks.github),
        DocumentSection("Sinhala Phonetic Orthography", "Copyright © 2026 Srilal Siriwardhana. Licensed under the MIT License. "
            + "Grammar-correct Smart Phonetic and the dictionary sound matching are ports of its reference code, and follow "
            + "its orthographic rules.", link: AksharaLinks.research),
        DocumentSection("A Word Frequency List for Sinhala", "The bundled word list is a compact derivative of the University "
            + "of Moratuwa National Languages Processing Centre word-frequency list. It retains the first 40,000 high-frequency "
            + "entries and filters malformed or overlong tokens.\n\nCitation: Aloka Fernando and Gihan Dias (2021), “Building "
            + "a Linguistic Resource: A Word Frequency List for Sinhala,” ICON 2021, pages 606–610.", link: AksharaLinks.frequencyList),
    ]
}

struct DocumentSection: Hashable {
    let title: String
    let body: String
    let link: URL?

    init(_ title: String, _ body: String, link: URL? = nil) {
        self.title = title
        self.body = body
        self.link = link
    }
}

/// A page of text over the Settings window: the privacy policy and the notices.
@available(macOS 11.0, *)
private struct DocumentSheet: View {
    let title: String
    let sections: [DocumentSection]
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.title2.weight(.semibold)).padding(20)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sections, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.title).font(.headline)
                            Text(section.body).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            if let link = section.link { Link(link.absoluteString, destination: link).font(.callout) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            Divider()
            HStack {
                Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 520, height: 480)
    }
}

/// The Akshara icon, name and a line under it, as the Android app's About header.
@available(macOS 11.0, *)
private struct AppHeader: View {
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text("Akshara").font(.title2.weight(.semibold))
                Text(subtitle).font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 4)
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
    let title: String?
    let content: Content

    init(_ title: String?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title { Text(title).font(.headline) }
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

@available(macOS 11.0, *)
private struct SettingsRow: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 16)
            Text(value).foregroundColor(.secondary).multilineTextAlignment(.trailing)
        }
    }
}

/// A row that does something: a title and a line under it, like the Android app's settings actions.
@available(macOS 11.0, *)
private struct SettingsButtonRow: View {
    let title: String
    let summary: String
    let systemImage: String
    var destructive = false
    let action: () -> Void

    init(_ title: String, _ summary: String, systemImage: String, destructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.summary = summary
        self.systemImage = systemImage
        self.destructive = destructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 20)
                    .foregroundColor(destructive ? .red : .accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundColor(destructive ? .red : .primary)
                    Text(summary).font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
