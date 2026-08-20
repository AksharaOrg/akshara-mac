import Foundation

let bundlePrefix = "com.local.inputmethod.Akshara"
let defaults = UserDefaults.standard
var domain = defaults.persistentDomain(forName: "com.apple.HIToolbox") ?? [:]
let sourceKeys = [
  "AppleEnabledInputSources",
  "AppleSelectedInputSources",
  "AppleInputSourceHistory"
]

func isAksharaEntry(_ entry: [String: Any]) -> Bool {
  let identityKeys = ["InputSourceID", "Bundle ID", "Input Mode"]
  return identityKeys.contains { key in
    guard let value = entry[key] as? String else { return false }
    return value.hasPrefix(bundlePrefix) || value.localizedCaseInsensitiveContains("Akshara")
  }
}

for key in sourceKeys {
  guard let entries = domain[key] as? [Any] else {
    continue
  }

  domain[key] = entries.filter { entry in
    guard let dictionary = entry as? [String: Any] else { return true }
    return !isAksharaEntry(dictionary)
  }
}

defaults.setPersistentDomain(domain, forName: "com.apple.HIToolbox")
defaults.synchronize()