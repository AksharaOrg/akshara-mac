import SwiftUI
import AppKit

@available(macOS 11.0, *)
struct WelcomeView: View {
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Text("Let’s set up Sinhala typing")
                    .font(.headline)

                Text("It only takes a moment. Choose the layout that feels most natural to you.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    SetupStep(number: 1, text: "Open Keyboard settings.") {
                        Button("Open Keyboard Settings", action: openKeyboardSettings)
                            .controlSize(.small)
                    }
                    SetupStep(number: 2, text: "Choose Input Sources, then select Edit.")
                    SetupStep(number: 3, text: "Select the Add (+) button below your input sources.")
                    SetupStep(number: 4, text: "Search for Sinhala, then choose an Akshara layout.")
                }

                GroupBox("Choose a typing style") {
                    VStack(alignment: .leading, spacing: 10) {
                        LayoutChoice(
                            title: "Akshara – Phonetic",
                            description: "Type Sinhala with familiar Roman letters, such as amma → අම්ම."
                        )
                        LayoutChoice(
                            title: "Akshara – Smart Phonetic",
                            description: "A faster phonetic style with handy combinations, such as Aa for ඇ."
                        )
                        LayoutChoice(
                            title: "Akshara – SLS1134",
                            description: "The familiar Wijesekara layout, with visual kombuva reordering."
                        )
                    }
                    .padding(.top, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SetupStep(number: 5, text: "Choose Akshara from the menu bar whenever you’re ready to type.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Button(action: openGitHubRepo) {
                    Label("GitHub", systemImage: "link")
                }
                .buttonStyle(.link)
                .help("View Akshara on GitHub")

                Spacer()

                Button("Start Typing") {
                    onDismiss?()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome to Akshara")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("A thoughtful Sinhala typing experience for your Mac")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private func openKeyboardSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.PreferenceKey.Keyboard") else { return }
        NSWorkspace.shared.open(url)
    }

    private func openGitHubRepo() {
        guard let url = URL(string: "https://github.com/AksharaOrg/akshara-mac") else { return }
        NSWorkspace.shared.open(url)
    }
}

@available(macOS 11.0, *)
private struct SetupStep<Content: View>: View {
    let number: Int
    let text: String
    let content: Content

    init(number: Int, text: String, @ViewBuilder content: () -> Content = { EmptyView() }) {
        self.number = number
        self.text = text
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("\(number).")
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .trailing)
            VStack(alignment: .leading, spacing: 5) {
                Text(text)
                content
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(macOS 11.0, *)
private struct LayoutChoice: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.callout.weight(.medium))
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
