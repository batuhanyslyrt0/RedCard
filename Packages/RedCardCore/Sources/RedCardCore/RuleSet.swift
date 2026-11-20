import Foundation

/// A term and how many points it adds to (or removes from) a message's score.
public struct WeightedTerm: Codable, Sendable, Equatable {
    public var term: String
    public var weight: Int

    public init(_ term: String, _ weight: Int) {
        self.term = term
        self.weight = weight
    }
}

/// Everything the classifier knows about bet SMS.
///
/// It is plain data on purpose: a later version can download a newer
/// `RuleSet` as JSON and use it without an app update.
public struct RuleSet: Codable, Sendable, Equatable {
    public var version: Int
    /// Betting and casino vocabulary.
    public var terms: [WeightedTerm]
    /// Phrases from legitimate messages (bank cards, one-time codes, cargo)
    /// that pull the score down. Weights are negative.
    public var safeTerms: [WeightedTerm]
    /// Word parts that mark a site or brand name as gambling, such as `bet` in `superbet`.
    public var gamblingStems: [String]
    /// Normal words that contain a gambling stem, such as `sohbet` or `rekabet`.
    public var stemStoplist: [String]
    public var shortenerDomains: [String]
    public var chatInviteDomains: [String]
    public var suspiciousTopLevelDomains: [String]
    public var gamblingTopLevelDomains: [String]
    public var trustedDomainSuffixes: [String]
    /// Top-level domains accepted when a link is written without `http` or `www`.
    public var knownTopLevelDomains: [String]
}

extension RuleSet {
    public enum ValidationError: Error, Equatable {
        case tooFewTerms
        case tooManyEntries
        case weightOutOfRange(String)
        case emptyTerm
    }

    /// Decodes and checks a downloaded rule set, so a broken or hostile file
    /// can never stop the filter from working or blow its memory limit.
    public static func validated(from data: Data) throws -> RuleSet {
        let rules = try JSONDecoder().decode(RuleSet.self, from: data)
        try rules.validate()
        return rules
    }

    public func validate() throws {
        // A real rule set always has dozens of terms; very few means the file is wrong.
        guard terms.count >= 20 else { throw ValidationError.tooFewTerms }

        let listSizes = [
            terms.count, safeTerms.count, gamblingStems.count, stemStoplist.count,
            shortenerDomains.count, chatInviteDomains.count, suspiciousTopLevelDomains.count,
            gamblingTopLevelDomains.count, trustedDomainSuffixes.count, knownTopLevelDomains.count
        ]
        guard listSizes.allSatisfy({ $0 <= 2_000 }) else { throw ValidationError.tooManyEntries }

        for term in terms + safeTerms {
            guard !term.term.trimmingCharacters(in: .whitespaces).isEmpty else { throw ValidationError.emptyTerm }
            guard (-100...100).contains(term.weight) else { throw ValidationError.weightOutOfRange(term.term) }
        }
    }
}
