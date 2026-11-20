import Foundation

/// Finds web addresses in a message, including ones disguised as
/// `site . com`, `site[.]com` or `site nokta com`.
enum LinkScanner {
    struct Link: Equatable {
        /// Lowercased host, without `www.`.
        let host: String
        var labels: [Substring] { host.split(separator: ".") }
        var topLevelDomain: String { labels.last.map(String.init) ?? "" }
        /// The label just before the TLD, for example `site` in `site.com.tr`.
        var siteName: String {
            let parts = labels
            guard parts.count >= 2 else { return host }
            let isSecondLevelTR = parts.count >= 3 && parts.last == "tr"
                && ["com", "net", "org", "gen", "biz", "info", "web"].contains(parts[parts.count - 2])
            return String(isSecondLevelTR ? parts[parts.count - 3] : parts[parts.count - 2])
        }
    }

    static func links(in plainText: String, knownTopLevelDomains: Set<String>) -> [Link] {
        let text = undisguise(plainText)
        let range = NSRange(text.startIndex..., in: text)
        var found: [Link] = []
        var seen: Set<String> = []

        for match in hostPattern.matches(in: text, range: range) {
            guard let hostRange = Range(match.range(at: 2), in: text) else { continue }
            let host = String(text[hostRange]).lowercased()
            let hasScheme = match.range(at: 1).location != NSNotFound
            let link = Link(host: host.hasPrefix("www.") ? String(host.dropFirst(4)) : host)

            // Without http/www, only accept real-looking TLDs so that
            // "kazandin.hemen" in a sentence is not mistaken for a link.
            guard hasScheme || knownTopLevelDomains.contains(link.topLevelDomain) else { continue }
            guard !link.topLevelDomain.allSatisfy(\.isNumber) else { continue }
            if seen.insert(link.host).inserted {
                found.append(link)
            }
        }
        return found
    }

    /// Rewrites common ways of hiding a dot in a domain.
    static func undisguise(_ text: String) -> String {
        var result = text
        for pattern in disguisedDots {
            result = result.replacingOccurrences(of: pattern, with: ".", options: .regularExpression)
        }
        return result
    }

    private static let disguisedDots = [
        #"\s*[\[\(\{]\s*(\.|nokta|dot)\s*[\]\)\}]\s*"#,
        #"(?<=[a-z0-9])\s+(nokta|dot)\s+(?=[a-z])"#,
        #"(?<=[a-z0-9])\s+\.\s*(?=[a-z]{2,})"#,
        #"(?<=[a-z0-9])\.\s+(?=(com|net|org|xyz|bet|site|live|top|vip|club)\b)"#
    ]

    // Group 1: optional scheme or www. Group 2: the host.
    private static let hostPattern: NSRegularExpression = {
        let pattern = #"(https?://|www\.)?((?:www\.)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]{2,24})"#
        // The pattern is a constant, so a failure here is a programming error.
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
}
