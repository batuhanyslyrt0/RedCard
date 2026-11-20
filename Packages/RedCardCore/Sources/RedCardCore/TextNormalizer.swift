import Foundation

/// Turns a raw SMS into forms that are easy to match against rules.
///
/// Bet spammers hide words with tricks such as `B.O.N.U.S`, `fr3esp1n`,
/// Cyrillic look-alike letters, zero-width characters or 𝐛𝐨𝐥𝐝 Unicode.
/// Every rule term goes through the same pipeline, so both sides always
/// meet in the same shape.
public struct NormalizedText: Sendable, Equatable {
    /// Lowercased, Turkish-folded text. Digits and punctuation are kept,
    /// so links and amounts can still be found.
    public let plain: String
    /// Words after leetspeak decoding and squeezing repeated letters.
    public let tokens: [String]
    /// All tokens joined with no separators. Used for long phrases that
    /// spammers split up with spaces or dots.
    public let compact: String
    /// Words from `plain` without leetspeak decoding, so brand names such as
    /// `bet365` or `1xbet` keep their digits.
    public let rawTokens: [String]
}

public enum TextNormalizer {
    public static func normalize(_ text: String) -> NormalizedText {
        let plain = plainForm(of: text)
        let decoded = joinSpacedLetters(in: plain)
        let tokens = decoded
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && !leetMap.keys.contains($0) })
            .map { squeeze(decodeLeet(String($0))) }
            .filter { !$0.isEmpty }
        let rawTokens = plain
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { squeeze(String($0)) }
        return NormalizedText(plain: plain, tokens: tokens, compact: tokens.joined(), rawTokens: rawTokens)
    }

    /// Normalizes a rule term (keyword or phrase) the same way as message text.
    public static func term(_ text: String) -> (tokens: [String], compact: String) {
        let normalized = normalize(text)
        return (normalized.tokens, normalized.compact)
    }

    // MARK: - Steps

    /// Unicode compatibility mapping, invisible characters removed, look-alike
    /// letters replaced, lowercased with Turkish rules, Turkish letters folded.
    static func plainForm(of text: String) -> String {
        // NFKC turns fullwidth and "mathematical bold" letters into plain ones.
        let compatible = text.precomposedStringWithCompatibilityMapping
        var result = ""
        result.reserveCapacity(compatible.count)

        for scalar in compatible.unicodeScalars {
            if invisibleScalars.contains(scalar.value) { continue }
            if let replacement = confusables[scalar] {
                result.unicodeScalars.append(replacement)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }

        let lowered = result.lowercased(with: turkish)
        let folded = lowered.folding(options: [.diacriticInsensitive], locale: turkish)
        return String(folded.map { turkishFold[$0] ?? $0 })
    }

    /// Joins runs of single letters split by separators: `b o n u s`,
    /// `d.e.n.e.m.e`, `c-a-s-i-n-o` become `bonus`, `deneme`, `casino`.
    static func joinSpacedLetters(in text: String) -> String {
        // Split into alternating pieces: words and the gaps between them.
        var pieces: [(text: String, isWord: Bool)] = []
        for character in text {
            let isWord = isJoinable(character)
            if let last = pieces.last, last.isWord == isWord {
                pieces[pieces.count - 1].text.append(character)
            } else {
                pieces.append((String(character), isWord))
            }
        }

        var output = ""
        var index = 0
        while index < pieces.count {
            let piece = pieces[index]
            if piece.isWord, piece.text.count == 1 {
                // Follow "x . y . z" while every word is a single character
                // and every gap is made only of separator characters.
                var letters = piece.text
                var cursor = index
                while cursor + 2 < pieces.count,
                      pieces[cursor + 1].text.allSatisfy(spacedSeparators.contains),
                      pieces[cursor + 2].isWord,
                      pieces[cursor + 2].text.count == 1 {
                    letters += pieces[cursor + 2].text
                    cursor += 2
                }
                if letters.count >= 3 {
                    output += letters
                    index = cursor + 1
                    continue
                }
            }
            output += piece.text
            index += 1
        }
        return output
    }

    /// Decodes leetspeak only inside words that also contain letters,
    /// so plain numbers such as `500` stay untouched.
    static func decodeLeet(_ token: String) -> String {
        guard token.contains(where: \.isLetter) else { return token }
        return String(token.map { leetMap[$0] ?? $0 })
            .filter { $0.isLetter || $0.isNumber }
    }

    /// Collapses repeated characters: `bonusss` → `bonus`, `freee` → `fre`.
    /// Rule terms are squeezed too, so `free` and `freeee` both match.
    static func squeeze(_ token: String) -> String {
        var result = ""
        var last: Character?
        for character in token where character != last {
            result.append(character)
            last = character
        }
        return result
    }

    // MARK: - Helpers

    private static func isJoinable(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || leetMap.keys.contains(character)
    }

    private static let turkish = Locale(identifier: "tr_TR")

    private static let turkishFold: [Character: Character] = [
        "ı": "i", "ş": "s", "ğ": "g", "ç": "c", "ö": "o", "ü": "u",
        "â": "a", "î": "i", "û": "u"
    ]

    // "!" and "|" are left out on purpose: "Hemen kazan!" must not become "kazani".
    static let leetMap: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
        "@": "a", "$": "s", "€": "e"
    ]

    private static let spacedSeparators: Set<Character> = [
        " ", ".", "-", "_", "*", "/", "•", "·", "~", "+", "=", ",", "\u{00A0}"
    ]

    /// Zero-width spaces, joiners, soft hyphens, bidi marks and the BOM.
    private static let invisibleScalars: Set<UInt32> = [
        0x00AD, 0x034F, 0x061C, 0x115F, 0x1160, 0x17B4, 0x17B5, 0x180E,
        0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C,
        0x202D, 0x202E, 0x2060, 0x2061, 0x2062, 0x2063, 0x2064, 0x2066,
        0x2067, 0x2068, 0x2069, 0x3164, 0xFEFF, 0xFFA0
    ]

    /// Cyrillic and Greek letters that look like Latin ones.
    private static let confusables: [Unicode.Scalar: Unicode.Scalar] = {
        let pairs: [(String, String)] = [
            ("а", "a"), ("в", "b"), ("е", "e"), ("ё", "e"), ("к", "k"), ("м", "m"),
            ("н", "h"), ("о", "o"), ("р", "p"), ("с", "c"), ("т", "t"), ("у", "y"),
            ("х", "x"), ("і", "i"), ("ї", "i"), ("ј", "j"), ("ѕ", "s"), ("ԁ", "d"),
            ("ԛ", "q"), ("ԝ", "w"), ("А", "A"), ("В", "B"), ("Е", "E"), ("К", "K"),
            ("М", "M"), ("Н", "H"), ("О", "O"), ("Р", "P"), ("С", "C"), ("Т", "T"),
            ("Х", "X"), ("І", "I"), ("Ѕ", "S"),
            ("α", "a"), ("β", "b"), ("ε", "e"), ("ι", "i"), ("κ", "k"), ("ν", "v"),
            ("ο", "o"), ("ρ", "p"), ("τ", "t"), ("υ", "u"), ("χ", "x"), ("Α", "A"),
            ("Β", "B"), ("Ε", "E"), ("Ι", "I"), ("Κ", "K"), ("Μ", "M"), ("Ν", "N"),
            ("Ο", "O"), ("Ρ", "P"), ("Τ", "T"), ("Χ", "X"), ("Ζ", "Z")
        ]
        var map: [Unicode.Scalar: Unicode.Scalar] = [:]
        for (from, to) in pairs {
            if let source = from.unicodeScalars.first, let target = to.unicodeScalars.first {
                map[source] = target
            }
        }
        return map
    }()
}
