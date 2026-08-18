#!/usr/bin/env swift

// Akshara Restart Dialog
// Shows a native NSAlert (same style as AutoUpdater dialogs) after installation.

import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// We need a brief run loop tick to let AppKit initialise before showing the alert
DispatchQueue.main.async {
    let alert = NSAlert()
    alert.messageText = "Akshara Installed"
    alert.informativeText = "Akshara has been installed successfully. Restart your Mac to ensure all changes take full effect."
    alert.addButton(withTitle: "Restart Now")
    alert.addButton(withTitle: "Later")
    alert.alertStyle = .informational

    // Use the Akshara app icon
    let iconPath = "\(NSHomeDirectory())/Library/Input Methods/Akshara.app/Contents/Resources/Akshara.icns"
    if let icon = NSImage(contentsOfFile: iconPath) {
        alert.icon = icon
    }

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        // Restart Now
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", "tell application \"System Events\" to restart"]
        try? task.run()
    }

    NSApp.terminate(nil)
}

app.run()
