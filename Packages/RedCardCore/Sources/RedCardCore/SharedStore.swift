import Foundation

/// Reads and writes `FilterSettings` in the App Group that the app and the
/// filter extension share.
///
/// Apple lets the filter extension *read* this container but never write to
/// it, so only the app calls `save(_:)`.
public struct SharedStore: Sendable {
    /// Must match the App Group in both targets' entitlements.
    public static let appGroupIdentifier = "group.com.batuhan.redcard"

    private static let settingsKey = "filterSettings"
    private static let rulesKey = "downloadedRules"
    private static let rulesCheckedKey = "rulesLastChecked"
    private let suiteName: String

    public init(suiteName: String = SharedStore.appGroupIdentifier) {
        self.suiteName = suiteName
    }

    public func load() -> FilterSettings {
        guard let data = defaults?.data(forKey: Self.settingsKey),
              let settings = try? JSONDecoder().decode(FilterSettings.self, from: data) else {
            return FilterSettings()
        }
        return settings
    }

    public func save(_ settings: FilterSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults?.set(data, forKey: Self.settingsKey)
    }

    // MARK: - Downloaded rules

    /// The rules to use: a downloaded rule set if it is newer than the one
    /// built into the app, otherwise the built-in rules.
    public func activeRules() -> RuleSet {
        guard let data = defaults?.data(forKey: Self.rulesKey),
              let downloaded = try? RuleSet.validated(from: data),
              downloaded.version > RuleSet.builtIn.version else {
            return .builtIn
        }
        return downloaded
    }

    /// Stores a downloaded rule set. Invalid data is ignored.
    /// - Returns: `true` when the rules were stored.
    @discardableResult
    public func saveDownloadedRules(_ data: Data) -> Bool {
        guard (try? RuleSet.validated(from: data)) != nil else { return false }
        defaults?.set(data, forKey: Self.rulesKey)
        return true
    }

    /// When the app last checked for new rules, successful or not.
    public var rulesLastChecked: Date? {
        get { defaults?.object(forKey: Self.rulesCheckedKey) as? Date }
        nonmutating set { defaults?.set(newValue, forKey: Self.rulesCheckedKey) }
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}
