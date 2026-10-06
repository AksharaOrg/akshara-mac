import Cocoa
import SwiftUI

@objc public class WelcomeWindowManager: NSObject, NSWindowDelegate {
    @objc public static let shared = WelcomeWindowManager()

    private var window: NSWindow?
    private var phoneticGuideWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var settingsModel: AnyObject?
    private var inputMethodWasActivated = false
    /// Set when a window was asked for (an akshara:// link), so the launch doesn't add the welcome window too.
    private var windowRequested = false

    private func ensureVisibleAppActivation() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
    }

    /// Centres a window on the display the pointer is on (the one in use), every time it is shown.
    /// `NSWindow.center()` puts windows a little above the middle, and only when they are created.
    private func centerOnActiveScreen(_ window: NSWindow) {
        window.layoutIfNeeded()
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main else {
            window.center()
            return
        }
        let area = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded()))
    }

    private func restoreAccessoryActivationIfPossible() {
        guard window == nil, phoneticGuideWindow == nil, settingsWindow == nil else { return }
        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static let welcomeShownVersionKey = "WelcomeShownVersion"

    /// Shows the welcome window on its own once per version, and only while no Akshara input source is
    /// enabled. The input method's process starts at every login and whenever macOS relaunches it, so
    /// showing it on every launch kept bringing it back. It stays one click away in the input menu and
    /// the Akshara Settings app.
    @objc public func showWelcomeWindowIfNeeded() {
        guard !inputMethodWasActivated, !windowRequested, window == nil, !AksharaSetup.isAksharaEnabled() else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Self.welcomeShownVersionKey) != version else { return }
        defaults.set(version, forKey: Self.welcomeShownVersionKey)
        showWelcomeWindow()
    }

    @objc public func markInputMethodActivated() {
        inputMethodWasActivated = true
    }

    @objc public func showWelcomeWindow() {
        ensureVisibleAppActivation()

        if let window = window {
            centerOnActiveScreen(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard #available(macOS 11.0, *) else { return }

        let welcomeView = WelcomeView(
            onDismiss: { [weak self] in
                self?.closeWelcomeWindow()
            }
        )

        let hostingController = NSHostingController(rootView: welcomeView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Welcome to Akshara"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.isRestorable = false
        // This manager owns the window. With the default (true), closing it also releases it, one release
        // more than Swift's reference holds, and the app crashes when the autorelease pool drains.
        newWindow.isReleasedWhenClosed = false
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.contentViewController = hostingController
        newWindow.delegate = self
        newWindow.level = .floating
        
        self.window = newWindow
        
        centerOnActiveScreen(newWindow)

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func closeWelcomeWindow() {
        window?.close()
        window = nil
        restoreAccessoryActivationIfPossible()
    }

    @objc public func showPhoneticGuideWithSmartMode(_ isSmart: Bool) {
        ensureVisibleAppActivation()

        if let window = phoneticGuideWindow {
            centerOnActiveScreen(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard #available(macOS 11.0, *) else { return }
        let modeName = isSmart ? "Smart Phonetic" : "Phonetic"
        
        let guideView = PhoneticGuideView(
            isSmart: isSmart,
            onDismiss: { [weak self] in
                self?.phoneticGuideWindow?.close()
                self?.phoneticGuideWindow = nil
            }
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: isSmart ? 600 : 540),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Akshara \(modeName) Guide"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isRestorable = false
        window.isReleasedWhenClosed = false   // owned by this manager; see showWelcomeWindow
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        
        window.contentViewController = NSHostingController(rootView: guideView)
        window.delegate = self
        centerOnActiveScreen(window)
        phoneticGuideWindow = window
        
        // Setup initial state for animation
        window.alphaValue = 0.0
        var frame = window.frame
        frame.origin.y += 8 // Start slightly higher for slide down effect
        window.setFrame(frame, display: false)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Animate fade-in and slide-down
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1.0
            frame.origin.y -= 8
            window.animator().setFrame(frame, display: true)
        }
    }

    // MARK: - akshara:// links

    /// Opens Akshara's windows from links, so the Akshara Settings app in /Applications can show them:
    /// akshara://settings, akshara://welcome, akshara://guide/smart and akshara://guide/phonetic.
    @objc public func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let text = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: text), url.scheme == "akshara" else { return }
        windowRequested = true
        open(url)
    }

    func open(_ url: URL) {
        switch (url.host ?? "", url.path) {
        case ("welcome", _): showWelcomeWindow()
        case ("guide", "/phonetic"): showPhoneticGuideWithSmartMode(false)
        case ("guide", _): showPhoneticGuideWithSmartMode(true)
        default: showSettingsWindow()
        }
    }

    /// Akshara's settings, like the Android app's (the input menu's "Settings…").
    @objc public func showSettingsWindow() {
        ensureVisibleAppActivation()
        guard #available(macOS 11.0, *) else { return }

        if let window = settingsWindow {
            (settingsModel as? SettingsModel)?.reload()
            if window.isMiniaturized { window.deminiaturize(nil) }
            centerOnActiveScreen(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let model = SettingsModel()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Akshara Settings"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView(model: model))
        window.delegate = self
        centerOnActiveScreen(window)
        settingsWindow = window
        settingsModel = model

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        if closingWindow === window {
            window = nil
            restoreAccessoryActivationIfPossible()
        } else if closingWindow === phoneticGuideWindow {
            phoneticGuideWindow = nil
            restoreAccessoryActivationIfPossible()
        } else if closingWindow === settingsWindow {
            settingsWindow = nil
            settingsModel = nil
            restoreAccessoryActivationIfPossible()
        }
    }
}
