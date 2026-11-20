import Foundation
import RedCardCore

/// Downloads newer filter rules, so new bet tricks can be caught without an
/// app update. It only *downloads* one public file: nothing about the person
/// or their messages is ever sent.
struct RuleUpdater {
    /// Where the published rules live (`Rules/rules.json` in the repository).
    /// Leave `nil` until the file is published; the app then keeps using the
    /// rules built into it.
    /// Example: `https://raw.githubusercontent.com/<account>/RedCard/main/Rules/rules.json`
    static let rulesURL: URL? = nil

    /// How often to look for new rules.
    static let checkInterval: TimeInterval = 24 * 60 * 60

    private let store: SharedStore
    private let session: URLSession

    init(store: SharedStore = SharedStore(), session: URLSession = .shared) {
        self.store = store
        self.session = session
    }

    /// Checks for new rules at most once a day.
    /// - Returns: `true` when newer rules were stored.
    @discardableResult
    func refreshIfNeeded(now: Date = .now) async -> Bool {
        guard let url = Self.rulesURL else { return false }
        if let lastChecked = store.rulesLastChecked, now.timeIntervalSince(lastChecked) < Self.checkInterval {
            return false
        }
        store.rulesLastChecked = now

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let downloaded = try? RuleSet.validated(from: data),
              downloaded.version > store.activeRules().version else {
            return false
        }
        return store.saveDownloadedRules(data)
    }
}
