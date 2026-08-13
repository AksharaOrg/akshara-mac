import SwiftUI
import AppKit

@available(macOS 11.0, *)
struct WelcomeView: View {
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to Akshara")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("සිංහල for macOS")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 32)

            VStack(alignment: .leading, spacing: 14) {
                // 1
                StepRow(number: "1", title: "Open keyboard settings") {
                    Button(action: openKeyboardSettings) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape")
                            Text("Open Keyboard Settings")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 1)
                }

                // 2
                StepRow(number: "2", title: "Find \"Input Sources\" and click \"Edit\"")

                // 3
                StepRow(number: "3", title: "In the list of input sources, press the \"+\" button at the bottom")

                // 4
                StepRow(number: "4", title: "Search for Sinhala")

                // 5
                StepRow(number: "5", title: "There will be 3 available options, pick your preference:") {
                    VStack(alignment: .leading, spacing: 6) {
                        OptionDetailRow(
                            title: "Akshara - Phonetic",
                            description: "Standard romanized Sinhala composition (e.g. 'amma' → 'අම්ම')."
                        )
                        OptionDetailRow(
                            title: "Akshara - Smart Phonetic",
                            description: "Simplified phonetic typing with quick combinations (e.g. 'Aa' for 'ඈ', 'x' for 'ං')."
                        )
                        OptionDetailRow(
                            title: "Akshara - SLS1134",
                            description: "Direct Wijesekara layout entry with automatic visual kombuva reordering."
                        )
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    )
                    .padding(.top, 1)
                }

                // 6
                StepRow(number: "6", title: "Open the input source menu and switch")
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )

            HStack {
                Spacer()

                Button(action: {
                    onDismiss?()
                }) {
                    HStack(spacing: 5) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }

        }
        .padding(12)
        .frame(width: 400)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .edgesIgnoringSafeArea(.all)
    }

    private func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.PreferenceKey.Keyboard") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct StepRow<Content: View>: View {
    let number: String
    let title: String
    let content: Content

    init(number: String, title: String, @ViewBuilder content: () -> Content = { EmptyView() }) {
        self.number = number
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 20, height: 20)
                Text(number)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                content
            }
            Spacer()
        }
    }
}

struct OptionDetailRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
            Text(description)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

class DraggableVisualEffectView: NSVisualEffectView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = DraggableVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
