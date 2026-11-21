import Foundation

/// Turns a message into the text the on-device model is trained on and
/// later reads: normalized words (leetspeak decoded, Turkish letters folded)
/// with every number replaced by "0", so the model learns patterns such as
/// "0 tl deneme bonusu" instead of memorizing codes, amounts or card numbers.
public enum BetTextModelInput {
    public static func text(for body: String) -> String {
        TextNormalizer.normalize(body).rawTokens
            .map { TextNormalizer.squeeze(TextNormalizer.decodeLeet($0)) }
            .map { $0.replacingOccurrences(of: "[0-9]+", with: "0", options: .regularExpression) }
            .joined(separator: " ")
    }
}
