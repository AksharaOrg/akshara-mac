import Cocoa
import SwiftUI

@objc public class WelcomeWindowManager: NSObject, NSWindowDelegate {
    @objc public static let shared = WelcomeWindowManager()

    private static let hasCompletedWelcomeKey = "AksharaHasCompletedWelcome"
    private var window: NSWindow?
    private var phoneticGuideWindow: NSWindow?

    /// The onboarding window is useful once after installation; subsequent
    /// input-method launches should stay invisible and lightweight.
    @objc public func showWelcomeWindowIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.hasCompletedWelcomeKey) else { return }
        showWelcomeWindow()
    }

    @objc public func showWelcomeWindow() {
        if let window = window {
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.center()
        newWindow.title = "Welcome to Akshara"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.isRestorable = false
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.contentViewController = hostingController
        newWindow.delegate = self

        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func closeWelcomeWindow() {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedWelcomeKey)
        window?.close()
        window = nil
    }

    @objc public func showPhoneticGuideWithSmartMode(_ isSmart: Bool) {
        if let window = phoneticGuideWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard #available(macOS 11.0, *) else { return }
        let modeName = isSmart ? "Smart Phonetic" : "Phonetic"
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: isSmart ? 580 : 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Akshara \(modeName) Guide"
        window.isRestorable = false
        window.contentViewController = NSHostingController(rootView: PhoneticGuideView(isSmart: isSmart))
        window.delegate = self
        window.center()
        phoneticGuideWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        if closingWindow === window {
            UserDefaults.standard.set(true, forKey: Self.hasCompletedWelcomeKey)
            window = nil
        } else if closingWindow === phoneticGuideWindow {
            phoneticGuideWindow = nil
        }
    }
}
