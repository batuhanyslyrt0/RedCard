import Foundation

/// How sure the classifier must be before a message goes to Junk.
public enum Strictness: String, Codable, CaseIterable, Sendable, Identifiable {
    case relaxed
    case balanced
    case strict

    public var id: String { rawValue }

    /// Minimum score for a message to be filtered.
    public var threshold: Int {
        switch self {
        case .relaxed: 70
        case .balanced: 50
        case .strict: 35
        }
    }
}

/// Words and senders the person adds themselves. These always win over
/// the built-in rules.
public struct UserRules: Codable, Sendable, Equatable {
    public var blockedWords: [String] = []
    public var blockedSenders: [String] = []
    public var allowedWords: [String] = []
    public var allowedSenders: [String] = []

    public init(
        blockedWords: [String] = [],
        blockedSenders: [String] = [],
        allowedWords: [String] = [],
        allowedSenders: [String] = []
    ) {
        self.blockedWords = blockedWords
        self.blockedSenders = blockedSenders
        self.allowedWords = allowedWords
        self.allowedSenders = allowedSenders
    }
}

/// Everything the app shares with the filter extension.
public struct FilterSettings: Codable, Sendable, Equatable {
    public var strictness: Strictness = .balanced
    public var userRules = UserRules()

    public init(strictness: Strictness = .balanced, userRules: UserRules = UserRules()) {
        self.strictness = strictness
        self.userRules = userRules
    }
}
