import Testing
@testable import RedCardCore

@Suite("Text normalizer")
struct NormalizerTests {
    @Test("Folds Turkish letters and case")
    func turkishFolding() {
        let text = TextNormalizer.normalize("ÇEVRİMSİZ Şans Iğdır")
        #expect(text.tokens == ["cevrimsiz", "sans", "igdir"])
    }

    @Test("Joins letters split by dots, spaces and dashes")
    func spacedLetters() {
        #expect(TextNormalizer.normalize("B.O.N.U.S").tokens == ["bonus"])
        #expect(TextNormalizer.normalize("d e n e m e bonusu").tokens == ["deneme", "bonusu"])
        #expect(TextNormalizer.normalize("c-a-s-i-n-o").tokens == ["casino"])
    }

    @Test("Decodes leetspeak inside words but keeps plain numbers")
    func leetspeak() {
        #expect(TextNormalizer.normalize("fr3esp1n").tokens == ["frespin"])
        #expect(TextNormalizer.normalize("b0nus 500").tokens == ["bonus", "50"])
        #expect(TextNormalizer.normalize("Hemen kazan!").tokens == ["hemen", "kazan"])
    }

    @Test("Removes invisible characters and look-alike letters")
    func unicodeTricks() {
        // Zero-width space inside the word, Cyrillic "а" and "о".
        #expect(TextNormalizer.normalize("bo\u{200B}nus").tokens == ["bonus"])
        #expect(TextNormalizer.normalize("cаsinо").tokens == ["casino"])
        // Mathematical bold letters.
        #expect(TextNormalizer.normalize("𝐁𝐎𝐍𝐔𝐒").tokens == ["bonus"])
    }

    @Test("Squeezes repeated letters")
    func repeatedLetters() {
        #expect(TextNormalizer.normalize("bonussss").tokens == ["bonus"])
    }
}
