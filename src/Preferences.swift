import Foundation

/// Akshara's settings, shown in the Settings window. Smart Phonetic v2 and its spelling options live in
/// `SmartPhoneticService`; these are the rest. All are on by default, as on Android.
@objc(AksharaPreferences)
final class Preferences: NSObject {
    @objc static let shared = Preferences(defaults: .standard)

    private static let showSuggestionsKey = "ShowSuggestions"
    private static let doubleSpacePeriodKey = "DoubleSpacePeriod"

    private let defaults: UserDefaults

    /// The candidate row under the word being typed (Grammar-correct Smart Phonetic).
    @objc var showSuggestions: Bool {
        didSet { defaults.set(showSuggestions, forKey: Self.showSuggestionsKey) }
    }
    /// Two quick spaces after a word insert ". ".
    @objc var doubleSpacePeriod: Bool {
        didSet { defaults.set(doubleSpacePeriod, forKey: Self.doubleSpacePeriodKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        showSuggestions = defaults.object(forKey: Self.showSuggestionsKey) as? Bool ?? true
        doubleSpacePeriod = defaults.object(forKey: Self.doubleSpacePeriodKey) as? Bool ?? true
        super.init()
    }
}
