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
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.contentViewController = hostingController
        newWindow.delegate = self
        newWindow.level = .floating
        
        self.window = newWindow
        
        // Exact mathematical centering using known 500x500 size
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.origin.x + (screenRect.width - 500) / 2
            let y = screenRect.origin.y + (screenRect.height - 500) / 2
            newWindow.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            newWindow.center()
        }

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
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        
        window.contentViewController = NSHostingController(rootView: guideView)
        window.delegate = self
        window.center()
        phoneticGuideWindow = window
        
        // Setup initial state for animation
        window.alphaValue = 0.0
        var frame = window.frame
        frame.origin.y += 20 // Start slightly higher for slide down effect
        window.setFrame(frame, display: false)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Animate fade-in and slide-down
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1.0
            frame.origin.y -= 20
            window.animator().setFrame(frame, display: true)
        }
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
