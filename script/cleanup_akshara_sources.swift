import Foundation

let knownPrefixes = [
  "com.local.inputmethod.Akshara",
  "com.local.inputmethod.SinhalaCleanIME",
  "Akshara",
  "SinhalaCleanIME",
  "CleanIME"
]

func matchesKnownInputSource(_ rawValue: Any?) -> Bool {
  guard let value = rawValue as? String else { return false }

  for prefix in knownPrefixes {
    if value == prefix || value.hasPrefix(prefix) || value.localizedCaseInsensitiveContains(prefix) {
      return true
    }
  }

  return false
}

func isStaleAksharaEntry(_ entry: [String: Any]) -> Bool {
  let identityKeys = ["InputSourceID", "Bundle ID", "Input Mode"]
  return identityKeys.contains { key in
    matchesKnownInputSource(entry[key])
  }
}

let defaults = UserDefaults.standard
var domain = defaults.persistentDomain(forName: "com.apple.HIToolbox") ?? [:]
let sourceKeys = [
  "AppleEnabledInputSources",
  "AppleSelectedInputSources",
  "AppleInputSourceHistory"
]

for key in sourceKeys {
  guard let entries = domain[key] as? [Any] else {
    continue
  }

  domain[key] = entries.filter { entry in
    guard let dictionary = entry as? [String: Any] else { return true }
    return !isStaleAksharaEntry(dictionary)
  }
}

defaults.setPersistentDomain(domain, forName: "com.apple.HIToolbox")
defaults.synchronize()