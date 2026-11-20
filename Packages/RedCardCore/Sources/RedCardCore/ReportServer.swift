import Foundation

/// Red Card's own server. It serves the rules file, the privacy policy and
/// receives the reports people send from Messages.
///
/// If the host changes, also change it in
/// `Config/RedCardReport-Info.plist` and `Config/RedCardReport.entitlements`.
public enum ReportServer {
    public static let host = "redcard.batudev.com"

    public static let rulesURL = URL(string: "https://\(host)/rules.json")!
    public static let privacyPolicyURL = URL(string: "https://\(host)/privacy")!
    public static let reportURL = URL(string: "https://\(host)/api/report")!
}

/// Builds the JSON body that iOS sends to the server when someone reports a
/// message. It deliberately contains no phone number, contact or device
/// identifier: only the message text, the kind of sender and what the
/// filter thought of it.
public enum ReportPayload {
    public enum Kind: String, Sendable {
        /// A bet message the filter missed.
        case junk
        /// A normal message the filter wrongly sent to Junk.
        case notJunk
    }

    public struct Message: Sendable {
        public let body: String
        public let sender: String?
        public let receivedAt: Date

        public init(body: String, sender: String?, receivedAt: Date) {
            self.body = body
            self.sender = sender
            self.receivedAt = receivedAt
        }
    }

    /// Longest message text included in a report.
    public static let maximumBodyLength = 2_000
    /// Most messages included in one report.
    public static let maximumMessages = 5

    public static func make(
        kind: Kind,
        messages: [Message],
        rules: RuleSet,
        settings: FilterSettings,
        appVersion: String
    ) -> [String: Any] {
        let classifier = BetClassifier(rules: rules, settings: settings)
        let iso = ISO8601DateFormatter()

        let entries: [[String: Any]] = messages.suffix(maximumMessages).map { message in
            let verdict = classifier.classify(body: message.body, sender: message.sender)
            return [
                "body": String(message.body.prefix(maximumBodyLength)),
                "senderType": SenderCategory.name(for: message.sender),
                // Day only: enough to see trends, not when someone read a message.
                "receivedDay": String(iso.string(from: message.receivedAt).prefix(10)),
                "localScore": verdict.score,
                "localThreshold": verdict.threshold,
                "localDecision": verdict.isJunk ? "junk" : "allow"
            ]
        }

        return [
            "app": "RedCard",
            "schema": 1,
            "report": kind.rawValue,
            "appVersion": appVersion,
            "rulesVersion": rules.version,
            "messages": entries
        ]
    }
}
