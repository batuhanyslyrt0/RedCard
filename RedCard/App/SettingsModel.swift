import Foundation
import Observation
import RedCardCore

/// The app's copy of the filter settings. Every change is written to the
/// shared App Group straight away, so the filter extension uses it on the
/// next message.
@MainActor
@Observable
final class SettingsModel {
    var strictness: Strictness {
        didSet { save() }
    }

    var userRules: UserRules {
        didSet { save() }
    }

    /// The rules the filter uses right now: downloaded ones if newer,
    /// otherwise the ones built into the app.
    private(set) var rules: RuleSet

    @ObservationIgnored private let store: SharedStore

    init(store: SharedStore = SharedStore()) {
        let settings = store.load()
        self.store = store
        self.strictness = settings.strictness
        self.userRules = settings.userRules
        self.rules = store.activeRules()
    }

    var settings: FilterSettings {
        FilterSettings(strictness: strictness, userRules: userRules)
    }

    /// A classifier with the current rules and settings, exactly like the
    /// one the filter extension builds for each message.
    func makeClassifier() -> BetClassifier {
        BetClassifier(rules: rules, settings: settings)
    }

    /// Looks for newer rules (at most once a day) and starts using them.
    func refreshRules() async {
        if await RuleUpdater(store: store).refreshIfNeeded() {
            rules = store.activeRules()
        }
    }

    func entries(in list: RuleList) -> [String] {
        userRules[keyPath: list.keyPath]
    }

    /// Adds an entry unless it is empty or already in the list.
    /// - Returns: `true` when the entry was added.
    @discardableResult
    func add(_ entry: String, to list: RuleList) -> Bool {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let existing = userRules[keyPath: list.keyPath]
        guard !existing.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return false
        }
        userRules[keyPath: list.keyPath].append(trimmed)
        return true
    }

    func remove(atOffsets offsets: IndexSet, from list: RuleList) {
        userRules[keyPath: list.keyPath].remove(atOffsets: offsets)
    }

    private func save() {
        store.save(settings)
    }
}

/// The four lists a person can edit.
enum RuleList: String, CaseIterable, Identifiable {
    case blockedWords
    case blockedSenders
    case allowedWords
    case allowedSenders

    var id: String { rawValue }

    var keyPath: WritableKeyPath<UserRules, [String]> {
        switch self {
        case .blockedWords: \.blockedWords
        case .blockedSenders: \.blockedSenders
        case .allowedWords: \.allowedWords
        case .allowedSenders: \.allowedSenders
        }
    }

    var isSenderList: Bool {
        self == .blockedSenders || self == .allowedSenders
    }
}
