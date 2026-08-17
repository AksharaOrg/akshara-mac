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
    @Published var instructionStep = 0
    
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
        .background(windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private var windowBackground: some View {
#if compiler(>=6.4)
        if #available(macOS 26.0, *) {
            GlassEffectBackground()
        } else {
            VisualEffectBackground()
        }
#else
        VisualEffectBackground()
#endif
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
                        viewModel.instructionStep = 0
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
            ZStack {
                if viewModel.instructionStep == 0 {
                    CarouselStepView(
                        imagePath: "welcome/welcome-1.png",
                        title: "Open Keyboard Settings",
                        description: "You've just opened the settings. Next, we will add the keyboard."
                    ).transition(.opacity)
                } else if viewModel.instructionStep == 1 {
                    CarouselStepView(
                        imagePath: "welcome/welcome-2.png",
                        title: "Edit Input Sources",
                        description: "Scroll down to 'Input Sources' or 'Text Input' and click the 'Edit...' button."
                    ).transition(.opacity)
                } else if viewModel.instructionStep == 2 {
                    CarouselStepView(
                        imagePath: "welcome/welcome-3.png",
                        title: "Add a New Keyboard",
                        description: "Click the Add (+) button at the bottom left of the input sources list."
                    ).transition(.opacity)
                } else if viewModel.instructionStep == 3 {
                    VStack(spacing: 8) {
                        if let url = Bundle.main.resourceURL?.appendingPathComponent("welcome/welcome-4.png"),
                           let img = NSImage(contentsOf: url) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                            
                        GroupBox("Available Layouts") {
                            VStack(alignment: .leading, spacing: 8) {
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
                            .padding(6)
                        }
                        .frame(maxWidth: 380)
                        
                        Spacer(minLength: 16)
                        
                        Text("Search & Choose Layout")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Search for 'Sinhala' and select an Akshara layout.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                } else if viewModel.instructionStep == 4 {
                    CarouselStepView(
                        imagePath: "welcome/welcome-5.png",
                        title: "Select from Menu Bar",
                        description: "Once added, choose Akshara from the input menu in your menu bar whenever you’re ready to type."
                    ).transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                Button(action: openGitHubRepo) {
                    Label("GitHub", systemImage: "link")
                }
                .buttonStyle(.link)
                .help("View Akshara on GitHub")

                Spacer()
                
                if viewModel.instructionStep > 0 {
                    Button(action: {
                        withAnimation {
                            viewModel.instructionStep -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.instructionStep < 4 {
                    Button(action: {
                        withAnimation {
                            viewModel.instructionStep += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        onDismiss?()
                    }) {
                        Text("Continue")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .padding(.top, 16)
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
private struct CarouselStepView: View {
    var icon: String? = nil
    var imagePath: String? = nil
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 6) {
            if let imagePath = imagePath,
               let url = Bundle.main.resourceURL?.appendingPathComponent(imagePath),
               let img = NSImage(contentsOf: url) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 340)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .frame(maxHeight: 340)
            }
            
            Spacer(minLength: 16)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .lineSpacing(2)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 8)
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
        view.material = .popover
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#if compiler(>=6.4)
@available(macOS 26.0, *)
class DraggableGlassEffectView: NSGlassEffectView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

@available(macOS 26.0, *)
struct GlassEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = DraggableGlassEffectView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSGlassEffectView, context: Context) {}
}
#endif


@available(macOS 11.0, *)
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
