import SwiftUI
import AppKit
import Carbon

@available(macOS 11.0, *)
class WelcomeViewModel: ObservableObject {
    enum ScreenState {
        case intro
        case notActivated
        case instructions
        case activated
    }

    @Published var currentScreen: ScreenState = .intro
    @Published var showTitle = false
    @Published var showSubtitle = false
    @Published var showStartButton = false
    
    private var checkTimer: Timer?

    func startAnimations() {
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            showSubtitle = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.8)) {
            showStartButton = true
        }
    }
    
    func checkActivationStatus() {
        if self.isAksharaEnabled() {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.currentScreen = .activated
            }
            return
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.currentScreen = .notActivated
            }
        }
        
        startPollingTimer()
    }
    
    func startPollingTimer() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isAksharaEnabled() {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.currentScreen = .activated
                    }
                    self.checkTimer?.invalidate()
                    self.checkTimer = nil
                }
            }
        }
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    private func isAksharaEnabled() -> Bool {
        let inputSourceID = "com.local.inputmethod.Akshara"
        let filter = [kTISPropertyInputSourceID as String: inputSourceID] as CFDictionary
        
        guard let sourceList = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }
        
        for source in sourceList {
            if let enablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                let isEnabled = Unmanaged<CFBoolean>.fromOpaque(enablePtr).takeUnretainedValue()
                if CFBooleanGetValue(isEnabled) {
                    return true
                }
            }
        }
        return false
    }
}

@available(macOS 11.0, *)
struct WelcomeView: View {
    var onDismiss: (() -> Void)?
    @ObservedObject private var viewModel = WelcomeViewModel()

    var body: some View {
        ZStack {
            if viewModel.currentScreen == .intro {
                introView
                    .transition(.opacity)
            } else if viewModel.currentScreen == .notActivated {
                notActivatedView
                    .transition(.opacity)
            } else if viewModel.currentScreen == .instructions {
                instructionsView
                    .transition(.opacity)
            } else if viewModel.currentScreen == .activated {
                activatedView
                    .transition(.opacity)
            }
        }
        .frame(width: 500, height: 500)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .edgesIgnoringSafeArea(.all)
    }

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            // Logo
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                Text("අ")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)
            }
            .opacity(viewModel.showTitle ? 1 : 0)
            .offset(y: viewModel.showTitle ? 0 : 10)
            
            VStack(spacing: 12) {
                Text("Akshara")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(viewModel.showTitle ? 1 : 0)
                    .offset(y: viewModel.showTitle ? 0 : 10)
                
                Text("A thoughtful Sinhala typing experience\nfor your Mac.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(viewModel.showSubtitle ? 1 : 0)
                    .offset(y: viewModel.showSubtitle ? 0 : 10)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.checkActivationStatus()
                }) {
                    HStack(spacing: 5) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .opacity(viewModel.showStartButton ? 1 : 0)
                .offset(y: viewModel.showStartButton ? 0 : 10)
                
                Text("By continuing, you agree to the Terms\nof Service and Privacy Policy.")
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                    .opacity(viewModel.showStartButton ? 1 : 0)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.startAnimations()
        }
    }

    private var notActivatedView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                Text("Not Activated Yet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Akshara keyboard is installed but needs to be added\nin your System Settings before you can use it.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    openKeyboardSettings()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        viewModel.currentScreen = .instructions
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape")
                        Text("Open Keyboard Settings")
                    }
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 24)
                
                Button(action: {
                    onDismiss?()
                }) {
                    Text("Close")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var instructionsView: some View {
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

                Button("Close") {
                    onDismiss?()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activatedView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Akshara is now activated and ready to use.\nYou can select it from the input menu in the menu bar.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    onDismiss?()
                }) {
                    HStack(spacing: 5) {
                        Text("Finish")
                        Image(systemName: "checkmark")
                    }
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 24)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
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

@available(macOS 11.0, *)
struct GitHubIconView: View {
    var body: some View {
        if let path = Bundle.main.path(forResource: "github", ofType: "svg"),
           let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "globe")
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
        view.material = .underWindowBackground
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

@available(macOS 11.0, *)
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
