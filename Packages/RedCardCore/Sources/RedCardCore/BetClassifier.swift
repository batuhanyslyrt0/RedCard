import Foundation

/// One reason that changed a message's score.
public struct Signal: Sendable, Hashable, Identifiable {
    public enum Kind: String, Sendable, Hashable {
        /// Betting or casino vocabulary.
        case gamblingTerm
        /// A brand-like word such as `superbet` or `bet365`.
        case gamblingBrand
        /// A link whose site name or ending points to gambling.
        case gamblingLink
        case shortLink
        case chatInvite
        case unusualLink
        case link
        case moneyAmount
        /// Foreign or email sender + money amount + unusual link.
        case promotionPattern
        case personalNumber
        case foreignNumber
        case emailSender
        case registeredSender
        case safeContext
        case userBlockedWord
        case userBlockedSender
        case userAllowedWord
        case userAllowedSender
    }

    public let kind: Kind
    /// What matched, for example the term or the domain.
    public let detail: String
    public let points: Int

    public var id: String { "\(kind.rawValue):\(detail)" }
}

/// The classifier's answer for one message.
public struct Verdict: Sendable, Equatable {
    public enum Decision: Sendable, Equatable {
        case allow
        case junk
    }

    public let decision: Decision
    public let score: Int
    public let threshold: Int
    public let signals: [Signal]

    public var isJunk: Bool { decision == .junk }
}

/// Decides whether an SMS is a bet / casino advert.
///
/// It works in three layers:
/// 1. The person's own allow and block lists, which always win.
/// 2. Gambling evidence: vocabulary, brand-like words and gambling links.
/// 3. Supporting evidence (short links, money amounts, the kind of sender)
///    that only counts once there is gambling evidence, so an ordinary
///    message with a link is never filtered for the link alone.
public struct BetClassifier: Sendable {
    private let rules: CompiledRules
    private let settings: FilterSettings
    private let userBlockedWords: [CompiledTerm]
    private let userAllowedWords: [CompiledTerm]

    public init(rules: RuleSet = .builtIn, settings: FilterSettings = FilterSettings()) {
        self.rules = rules == .builtIn ? CompiledRules.builtIn : CompiledRules(rules)
        self.settings = settings
        self.userBlockedWords = settings.userRules.blockedWords.compactMap(CompiledTerm.init(text:))
        self.userAllowedWords = settings.userRules.allowedWords.compactMap(CompiledTerm.init(text:))
    }

    public func classify(body: String, sender: String?) -> Verdict {
        let threshold = settings.strictness.threshold
        let text = TextNormalizer.normalize(body)
        let senderInfo = SenderInfo(sender)

        // 1. The person's own lists.
        if let sender = senderInfo, let match = sender.matches(any: settings.userRules.allowedSenders) {
            return Verdict(decision: .allow, score: 0, threshold: threshold,
                           signals: [Signal(kind: .userAllowedSender, detail: match, points: 0)])
        }
        if let sender = senderInfo, let match = sender.matches(any: settings.userRules.blockedSenders) {
            return Verdict(decision: .junk, score: threshold, threshold: threshold,
                           signals: [Signal(kind: .userBlockedSender, detail: match, points: threshold)])
        }
        if let match = userAllowedWords.first(where: { $0.matches(text) }) {
            return Verdict(decision: .allow, score: 0, threshold: threshold,
                           signals: [Signal(kind: .userAllowedWord, detail: match.original, points: 0)])
        }
        if let match = userBlockedWords.first(where: { $0.matches(text) }) {
            return Verdict(decision: .junk, score: threshold, threshold: threshold,
                           signals: [Signal(kind: .userBlockedWord, detail: match.original, points: threshold)])
        }

        // 2. Gambling evidence.
        var signals = matchedTerms(rules.terms, in: text).map {
            Signal(kind: .gamblingTerm, detail: $0.original, points: $0.weight)
        }
        signals += brandSignals(in: text)

        let links = LinkScanner.links(in: text.plain, knownTopLevelDomains: rules.knownTopLevelDomains)
        let linkSignals = links.flatMap(linkSignals(for:))
        signals += linkSignals.filter { $0.kind == .gamblingLink }

        // Bet spam that avoids every betting word ("Bns", "7200 lira, tüm
        // üyelere", odd link) still has a typical shape: a foreign number or
        // email address, a money amount and an unusual or shortened link.
        // Only those senders count, so a friend sending "500 TL attım,
        // dekont: bit.ly/…" from a Turkish number is never caught by this.
        let amount = firstMoneyAmount(in: text.plain)
        let hasUnusualLink = linkSignals.contains { [.shortLink, .unusualLink, .chatInvite].contains($0.kind) }
        if amount != nil, hasUnusualLink, let kind = senderInfo?.kind, kind == .foreignNumber || kind == .email {
            signals.append(Signal(kind: .promotionPattern, detail: "", points: 25))
        }

        let hasGamblingEvidence = signals.contains { $0.points > 0 }
        guard hasGamblingEvidence else {
            return Verdict(decision: .allow, score: 0, threshold: threshold, signals: [])
        }

        // 3. Supporting evidence and legitimate context.
        signals += linkSignals.filter { $0.kind != .gamblingLink }
        if let amount {
            signals.append(Signal(kind: .moneyAmount, detail: amount, points: 10))
        }
        if let senderSignal = senderInfo?.signal {
            signals.append(senderSignal)
        }
        for term in matchedTerms(rules.safeTerms, in: text) {
            signals.append(Signal(kind: .safeContext, detail: term.original, points: term.weight))
        }

        let score = signals.reduce(0) { $0 + $1.points }
        return Verdict(decision: score >= threshold ? .junk : .allow,
                       score: score, threshold: threshold, signals: signals)
    }

    // MARK: - Terms

    /// Matching terms, without the ones that are part of a longer match:
    /// when "deneme bonusu" matches, "deneme bonus" and "bonus" don't count again.
    private func matchedTerms(_ terms: [CompiledTerm], in text: NormalizedText) -> [CompiledTerm] {
        let matches = terms.filter { $0.matches(text) }
        return matches.filter { term in
            !matches.contains { other in
                other.compact.count > term.compact.count && other.compact.contains(term.compact)
            }
        }
    }

    // MARK: - Brands

    private func brandSignals(in text: NormalizedText) -> [Signal] {
        var signals: [Signal] = []
        // Raw words first (they keep digits: "bet365"), then decoded words
        // that are not just a raw word decoded again, so "Bet1" counts once
        // and not also as "beti".
        let decodedRaw = Set(text.rawTokens.map { TextNormalizer.squeeze(TextNormalizer.decodeLeet($0)) })
        let candidates = text.rawTokens + text.tokens.filter { !decodedRaw.contains($0) }
        var seen: Set<String> = []

        for token in candidates where token.count >= 3 && seen.insert(token).inserted {
            guard !rules.stemStoplist.contains(where: token.contains) else { continue }

            if token == "bet" {
                signals.append(Signal(kind: .gamblingBrand, detail: token, points: 20))
            } else if token.contains("bet") {
                // bet365, 1xbet and similar carry digits; they are almost
                // never anything but a betting brand.
                let points = token.contains(where: \.isNumber) ? 40 : 30
                signals.append(Signal(kind: .gamblingBrand, detail: token, points: points))
            } else if rules.embeddedStems.contains(where: { token.contains($0) && !token.hasPrefix($0) }) {
                // A stem inside a longer word: "superbahis", "royalcasino".
                // Words that start with the stem are already covered by terms.
                signals.append(Signal(kind: .gamblingBrand, detail: token, points: 30))
            }
            if signals.count >= 3 { break }
        }
        return signals
    }

    // MARK: - Links

    private func linkSignals(for link: LinkScanner.Link) -> [Signal] {
        if rules.trustedDomainSuffixes.contains(where: { link.host == $0 || link.host.hasSuffix("." + $0) }) {
            return []
        }

        var signals: [Signal] = []
        let site = TextNormalizer.squeeze(link.siteName)
        let siteIsStoplisted = rules.stemStoplist.contains(where: site.contains)

        if rules.gamblingTopLevelDomains.contains(link.topLevelDomain)
            || (!siteIsStoplisted && rules.gamblingStems.contains(where: site.contains)) {
            signals.append(Signal(kind: .gamblingLink, detail: link.host, points: 45))
        }

        if rules.shortenerDomains.contains(link.host) {
            signals.append(Signal(kind: .shortLink, detail: link.host, points: 15))
        } else if rules.chatInviteDomains.contains(link.host) {
            signals.append(Signal(kind: .chatInvite, detail: link.host, points: 15))
        } else if rules.suspiciousTopLevelDomains.contains(link.topLevelDomain)
                    || site.contains(where: \.isNumber) {
            signals.append(Signal(kind: .unusualLink, detail: link.host, points: 10))
        } else {
            signals.append(Signal(kind: .link, detail: link.host, points: 5))
        }
        return signals
    }

    // MARK: - Amounts

    private func firstMoneyAmount(in plain: String) -> String? {
        let range = NSRange(plain.startIndex..., in: plain)
        guard let match = Self.amountPattern.firstMatch(in: plain, range: range),
              let matchRange = Range(match.range, in: plain) else { return nil }
        return String(plain[matchRange]).trimmingCharacters(in: .whitespaces)
    }

    /// `%100`, `500 TL`, `1.000₺`, `250 FS`, `100 freespin`, `x50`.
    private static let amountPattern: NSRegularExpression = {
        let pattern = #"(%\s?\d{2,3})|(\d{1,3}(?:[.,]\d{3})*\s?(?:tl|₺|try|lira|usd|eur|\$|€))|(\d{1,4}\s?(?:fs|free\s?spin|freespin|spin|spn)\b)|(\bx\d{2,5}\b)"#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
}

// MARK: - Compiled rules

/// A rule term prepared once for fast matching.
struct CompiledTerm: Sendable {
    let original: String
    let tokens: [String]
    let compact: String
    let weight: Int

    init(_ term: WeightedTerm) {
        let normalized = TextNormalizer.term(term.term)
        original = term.term
        tokens = normalized.tokens
        compact = normalized.compact
        weight = term.weight
    }

    init?(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.init(WeightedTerm(trimmed, 0))
        guard !tokens.isEmpty else { return nil }
    }

    /// Matches whole words in order. The last word may carry a Turkish
    /// suffix (`bonus` matches `bonusu`, `bahis` matches `bahisler`).
    /// Long phrases also match inside the compact text, which catches
    /// splits such as `deneme-bo nusu`.
    func matches(_ text: NormalizedText) -> Bool {
        guard !tokens.isEmpty else { return false }
        let words = text.tokens

        if tokens.count <= words.count {
            for start in 0...(words.count - tokens.count) {
                var matched = true
                for (offset, termToken) in tokens.enumerated() {
                    let word = words[start + offset]
                    let isLast = offset == tokens.count - 1
                    let ok = isLast && termToken.count >= 4 ? word.hasPrefix(termToken) : word == termToken
                    if !ok {
                        matched = false
                        break
                    }
                }
                if matched { return true }
            }
        }
        return compact.count >= 8 && text.compact.contains(compact)
    }
}

struct CompiledRules: Sendable {
    let terms: [CompiledTerm]
    let safeTerms: [CompiledTerm]
    let gamblingStems: [String]
    /// Stems checked inside longer brand-like words. `bet` is handled separately.
    let embeddedStems: [String]
    let stemStoplist: [String]
    let shortenerDomains: Set<String>
    let chatInviteDomains: Set<String>
    let suspiciousTopLevelDomains: Set<String>
    let gamblingTopLevelDomains: Set<String>
    let trustedDomainSuffixes: [String]
    let knownTopLevelDomains: Set<String>

    static let builtIn = CompiledRules(.builtIn)

    init(_ rules: RuleSet) {
        terms = rules.terms.map(CompiledTerm.init)
        safeTerms = rules.safeTerms.map(CompiledTerm.init)
        // Squeezing can shorten a stem into a common syllable ("iddaa" becomes
        // "ida", found in "adidas" and "sayıda"), so very short stems are left
        // out. `bet` is handled separately with its own stoplist.
        gamblingStems = rules.gamblingStems.map(TextNormalizer.squeeze).filter { $0 == "bet" || $0.count >= 4 }
        embeddedStems = gamblingStems.filter { $0 != "bet" && $0.count >= 5 }
        stemStoplist = rules.stemStoplist.map(TextNormalizer.squeeze)
        shortenerDomains = Set(rules.shortenerDomains)
        chatInviteDomains = Set(rules.chatInviteDomains)
        suspiciousTopLevelDomains = Set(rules.suspiciousTopLevelDomains)
        gamblingTopLevelDomains = Set(rules.gamblingTopLevelDomains)
        trustedDomainSuffixes = rules.trustedDomainSuffixes
        knownTopLevelDomains = Set(rules.knownTopLevelDomains)
    }
}

// MARK: - Sender

/// What can be told about who sent the message.
struct SenderInfo {
    enum Kind {
        case personalNumber
        case foreignNumber
        case shortCode
        case otherNumber
        case email
        case alphanumeric
    }

    let raw: String
    let kind: Kind
    private let digits: String

    init?(_ sender: String?) {
        guard let sender = sender?.trimmingCharacters(in: .whitespacesAndNewlines), !sender.isEmpty else {
            return nil
        }
        raw = sender
        digits = sender.filter(\.isNumber)

        if sender.contains("@") {
            kind = .email
        } else if sender.contains(where: \.isLetter) {
            kind = .alphanumeric
        } else if digits.count <= 6 {
            kind = .shortCode
        } else if Self.isTurkishMobile(digits) {
            kind = .personalNumber
        } else if sender.hasPrefix("+") || sender.hasPrefix("00") {
            kind = digits.hasPrefix("90") ? .otherNumber : .foreignNumber
        } else {
            kind = .otherNumber
        }
    }

    /// Supporting evidence from the sender. Only used when the message
    /// already looks like gambling.
    var signal: Signal? {
        switch kind {
        case .personalNumber: Signal(kind: .personalNumber, detail: raw, points: 10)
        case .foreignNumber: Signal(kind: .foreignNumber, detail: raw, points: 10)
        case .email: Signal(kind: .emailSender, detail: raw, points: 10)
        // Company-style sender IDs (ESLEMREKL, TEKSOYESYA …) are now widely
        // used by bet spammers too, so they earn no trust either way.
        case .alphanumeric: nil
        case .shortCode, .otherNumber: nil
        }
    }

    /// Returns the first entry that refers to this sender.
    /// Numbers compare by their last 10 digits, so `0532…`, `+90532…`
    /// and `532…` are the same person.
    func matches(any entries: [String]) -> String? {
        entries.first { entry in
            let entryDigits = entry.filter(\.isNumber)
            let entryHasLetters = entry.contains(where: \.isLetter)
            if !entryHasLetters, entryDigits.count >= 7, digits.count >= 7 {
                return entryDigits.suffix(10) == digits.suffix(10)
            }
            return entry.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(raw) == .orderedSame
        }
    }

    private static func isTurkishMobile(_ digits: String) -> Bool {
        let national: Substring
        if digits.hasPrefix("90"), digits.count == 12 {
            national = digits.dropFirst(2)
        } else if digits.hasPrefix("0"), digits.count == 11 {
            national = digits.dropFirst(1)
        } else if digits.count == 10 {
            national = Substring(digits)
        } else {
            return false
        }
        return national.hasPrefix("5")
    }
}

// MARK: - Public sender description

/// A privacy-friendly description of a sender, used in reports instead of
/// the number itself: `personalNumber`, `foreignNumber`, `shortCode`,
/// `otherNumber`, `email`, `alphanumeric` or `unknown`.
public enum SenderCategory {
    public static func name(for sender: String?) -> String {
        guard let info = SenderInfo(sender) else { return "unknown" }
        switch info.kind {
        case .personalNumber: return "personalNumber"
        case .foreignNumber: return "foreignNumber"
        case .shortCode: return "shortCode"
        case .otherNumber: return "otherNumber"
        case .email: return "email"
        case .alphanumeric: return "alphanumeric"
        }
    }
}
