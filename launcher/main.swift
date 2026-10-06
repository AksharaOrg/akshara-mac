import AppKit

// Akshara Settings: the app in /Applications (and so in Launchpad / Apps and Spotlight) for Akshara.
//
// An input method must live in an Input Methods folder, where the app launcher doesn't look, so this
// small app opens the input method's own Settings window instead, with an akshara:// link
// (WelcomeWindowManager.open). The windows and settings stay in the input method's process.
//
//     Akshara Settings                     → akshara://settings
//     Akshara Settings --open welcome      → akshara://welcome  (also guide/smart, guide/phonetic)

let inputMethodID = "com.local.inputmethod.Akshara"
let installedPaths = [
    NSHomeDirectory() + "/Library/Input Methods/Akshara.app",
    "/Library/Input Methods/Akshara.app",
]

/// The input method to talk to: the running one first, so the link reaches the process that types.
func inputMethodURL() -> URL? {
    if let running = NSRunningApplication.runningApplications(withBundleIdentifier: inputMethodID).first?.bundleURL {
        return running
    }
    return installedPaths.first(where: FileManager.default.fileExists(atPath:)).map(URL.init(fileURLWithPath:))
}

let arguments = CommandLine.arguments
let page = arguments.firstIndex(of: "--open").flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
let link = URL(string: "akshara://\(page ?? "settings")")!

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard let inputMethod = inputMethodURL() else {
    app.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Akshara isn't installed"
    alert.informativeText = "Akshara Settings opens the Akshara input method's settings. Install Akshara, then try again."
    alert.addButton(withTitle: "Download Akshara")
    alert.addButton(withTitle: "Close")
    if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.open(URL(string: "https://github.com/AksharaOrg/akshara-mac/releases/latest")!)
    }
    exit(1)
}

let configuration = NSWorkspace.OpenConfiguration()
configuration.activates = true
NSWorkspace.shared.open([link], withApplicationAt: inputMethod, configuration: configuration) { _, error in
    if let error = error {
        NSLog("Akshara Settings: could not open \(link) with \(inputMethod.path): \(error)")
        exit(1)
    }
    exit(0)
}
app.run()
