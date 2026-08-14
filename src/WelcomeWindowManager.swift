import Cocoa
import SwiftUI

@objc public class WelcomeWindowManager: NSObject {
    @objc public static let shared = WelcomeWindowManager()

    private var window: NSWindow?

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
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 490),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.center()
        newWindow.title = ""
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.isMovableByWindowBackground = true
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating

        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func closeWelcomeWindow() {
        window?.orderOut(nil)
    }
}
