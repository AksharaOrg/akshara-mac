import Carbon
import Foundation

let appPath = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "\(NSHomeDirectory())/Library/Input Methods/Akshara.app"
let appURL = URL(fileURLWithPath: appPath) as CFURL

func stringProperty(_ source: TISInputSource, _ key: CFString) -> String {
  guard let raw = TISGetInputSourceProperty(source, key) else {
    return ""
  }
  return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
}

func hasRegisteredInputSource(for bundleID: String) -> Bool {
  let sources = TISCreateInputSourceList(nil, true).takeRetainedValue() as NSArray
  for case let source as TISInputSource in sources {
    let sourceID = stringProperty(source, kTISPropertyInputSourceID)
    if sourceID == bundleID || sourceID.hasPrefix(bundleID + ".") {
      return true
    }
  }
  return false
}

let bundleID = Bundle(url: appURL as URL)?.bundleIdentifier ?? "com.local.inputmethod.Akshara"
if !hasRegisteredInputSource(for: bundleID) {
  let registerStatus = TISRegisterInputSource(appURL)
  if registerStatus != noErr {
    fputs("TISRegisterInputSource failed: \(registerStatus)\n", stderr)
    exit(1)
  }
}

print("Registered Akshara input sources")
