import Foundation
import RedCardCore

extension Signal {
    /// A short, plain description of why this signal counted.
    var title: LocalizedStringResource {
        switch kind {
        case .gamblingTerm: "Betting word “\(detail)”"
        case .gamblingBrand: "Betting brand name “\(detail)”"
        case .gamblingLink: "Link to a betting site: \(detail)"
        case .shortLink: "Shortened link: \(detail)"
        case .chatInvite: "Chat group invite: \(detail)"
        case .unusualLink: "Unusual link: \(detail)"
        case .link: "Link: \(detail)"
        case .moneyAmount: "Money or bonus amount “\(detail)”"
        case .personalNumber: "Sent from a personal mobile number"
        case .foreignNumber: "Sent from a foreign number"
        case .emailSender: "Sent from an email address"
        case .registeredSender: "Sent under a registered company name"
        case .safeContext: "Looks like an ordinary message: “\(detail)”"
        case .userBlockedWord: "Matches your blocked word “\(detail)”"
        case .userBlockedSender: "Sender is on your blocked list: \(detail)"
        case .userAllowedWord: "Matches your allowed word “\(detail)”"
        case .userAllowedSender: "Sender is on your allowed list: \(detail)"
        }
    }

    var systemImage: String {
        switch kind {
        case .gamblingTerm: "text.quote"
        case .gamblingBrand: "tag"
        case .gamblingLink, .unusualLink, .link: "link"
        case .shortLink: "link.badge.plus"
        case .chatInvite: "bubble.left.and.bubble.right"
        case .moneyAmount: "turkishlirasign"
        case .personalNumber, .foreignNumber: "phone"
        case .emailSender: "at"
        case .registeredSender: "building.2"
        case .safeContext: "checkmark.shield"
        case .userBlockedWord, .userBlockedSender: "hand.raised"
        case .userAllowedWord, .userAllowedSender: "hand.thumbsup"
        }
    }
}
