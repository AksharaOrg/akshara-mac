import Foundation

/// Smart Phonetic v2 for the input controller: the setting and its spelling options, the converter, and the
/// bundled word list that picks the dictionary spelling of what was typed (හොඳ for "honda"). It follows
/// Android's `PredictionRepository.phoneticChoice` / `phoneticCandidates`, ranked by word frequency only:
/// there is no next-word context or learning on macOS yet.
///
/// The word list loads once, in the background; until it is ready the converter's spelling is used as is.
/// Call it from the main thread (IMK delivers input there).
@objc(AksharaSmartPhonetic)
final class SmartPhoneticService: NSObject {
    @objc static let shared = SmartPhoneticService(defaults: .standard)

    private static let enabledKey = "SmartPhoneticV2"
    private static let archaicKey = "SmartPhoneticV2Archaic"
    private static let repayaZwjKey = "SmartPhoneticV2RepayaZwj"
    private static let classicalKey = "SmartPhoneticV2Classical"
    private static let rakaransayaUKey = "SmartPhoneticV2RakaransayaU"
    /// How many whole words and completions to consider before ranking (Android's PHONETIC_POOL).
    private static let pool = 12

    private let defaults: UserDefaults
    private var lexicon: SoundLexicon?
    private var loading = false

    /// Changes whenever the setting or an option does, so cached renderings can be dropped.
    @objc private(set) var generation = 0

    /// Grammar-correct Smart Phonetic, on by default; off types the classic Smart Phonetic.
    @objc var enabled: Bool {
        didSet { save(enabled, Self.enabledKey) }
    }
    /// The converter's options (SmartPhoneticV2.Options), all off by default.
    @objc var archaic: Bool { didSet { save(archaic, Self.archaicKey) } }
    @objc var repayaZwj: Bool { didSet { save(repayaZwj, Self.repayaZwjKey) } }
    @objc var classical: Bool { didSet { save(classical, Self.classicalKey) } }
    @objc var rakaransayaU: Bool { didSet { save(rakaransayaU, Self.rakaransayaUKey) } }

    var options: SmartPhoneticV2.Options {
        SmartPhoneticV2.Options(archaic: archaic, repayaZwj: repayaZwj, classical: classical, rakaransayaU: rakaransayaU)
    }

    /// True once the word list is ready.
    @objc var isLoaded: Bool { lexicon != nil }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        enabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        archaic = defaults.bool(forKey: Self.archaicKey)
        repayaZwj = defaults.bool(forKey: Self.repayaZwjKey)
        classical = defaults.bool(forKey: Self.classicalKey)
        rakaransayaU = defaults.bool(forKey: Self.rakaransayaUKey)
        super.init()
    }

    private func save(_ value: Bool, _ key: String) {
        defaults.set(value, forKey: key)
        generation += 1
    }

    /// The converter's spelling of a romanized word with the current options.
    @objc func transliterate(_ source: String) -> String {
        SmartPhoneticV2.transliterate(source, options: options)
    }

    /// Loads the bundled word list in the background, once.
    @objc func warmUp() {
        guard lexicon == nil, !loading else { return }
        guard let url = Bundle.main.url(forResource: "sinhala_frequency_model", withExtension: "tsv") else {
            NSLog("Akshara: sinhala_frequency_model.tsv is missing; Smart Phonetic uses rule spellings only")
            return
        }
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let rows = (try? String(contentsOf: url, encoding: .utf8)).map(SoundLexicon.parse) ?? []
            let lexicon = SoundLexicon(rows)
            DispatchQueue.main.async {
                self.lexicon = lexicon
                self.loading = false
            }
        }
    }

    /// Uses `lexicon` instead of the bundled list (tests).
    func load(_ lexicon: SoundLexicon) {
        self.lexicon = lexicon
    }

    /// The word Space commits for a romanized word, or nil to keep the converter's spelling.
    @objc func choice(forRoman roman: String) -> String? {
        guard let lexicon = lexicon, !roman.isEmpty else { return nil }
        return words(lexicon, roman).first
    }

    /// Whole words that sound like `roman`, then completions of it, most frequent first.
    @objc func candidates(forRoman roman: String, limit: Int) -> [String] {
        guard let lexicon = lexicon, !roman.isEmpty, limit > 0 else { return [] }
        let completions = byFrequency(lexicon.candidates(roman, limit: Self.pool, partial: true, options: options), lexicon)
        var seen = Set<String>()
        return Array((words(lexicon, roman) + completions).filter { seen.insert($0).inserted }.prefix(limit))
    }

    /// Whole words that sound like `roman`. An explicit spelling (`kazda`, `aa` …) that is a word stays first.
    private func words(_ lexicon: SoundLexicon, _ roman: String) -> [String] {
        let options = self.options
        // Candidates come back in the style of the options; keep those whose dictionary spelling is a word.
        let exact = lexicon.candidates(roman, limit: Self.pool, options: options).filter { countOf(lexicon, $0) > 0 }
        let spelled = SmartPhoneticV2.transliterate(roman, options: options)
        let pinned = exact.first.flatMap { $0 == spelled && SoundLexicon.isExplicit(roman) ? $0 : nil }
        let ranked = byFrequency(exact, lexicon)
        return (pinned.map { [$0] } ?? []) + ranked.filter { $0 != pinned }
    }

    /// Most frequent first; equal counts keep their order.
    private func byFrequency(_ words: [String], _ lexicon: SoundLexicon) -> [String] {
        words.enumerated()
            .map { (offset: $0.offset, word: $0.element, count: countOf(lexicon, $0.element)) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.offset < $1.offset }
            .map { $0.word }
    }

    /// Frequency of a word as shown in the options' style: the most frequent dictionary spelling that restyles to it.
    private func countOf(_ lexicon: SoundLexicon, _ word: String) -> Int {
        if let n = lexicon.count[word] { return n }
        let options = self.options
        return lexicon.exact(SoundLexicon.soundKey(word))
            .filter { SoundLexicon.restyle($0, options: options) == word }
            .compactMap { lexicon.count[$0] }
            .max() ?? 0
    }
}
