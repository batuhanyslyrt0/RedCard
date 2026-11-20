import Testing
@testable import RedCardCore

@Suite("Bet classifier")
struct ClassifierTests {
    let classifier = BetClassifier()

    // MARK: - Messages that must be filtered

    @Test("Filters typical bet SMS", arguments: [
        "Deneme bonusu 500 TL! Hemen giriş yap: bit.ly/3xYz",
        "%100 YATIRIM BONUSU + 250 FREESPIN. Güncel giriş: superbet482.com",
        "Canlı casino ve slot oyunlarında %50 kayıp bonusu seni bekliyor",
        "D.E.N.E.M.E B.O.N.U.S.U veriyoruz, çevrimsiz! t.me/kazancgrubu",
        "Adresimiz değişti! Yeni giriş adresi: betxyz . com",
        "Hafta sonu maçlarında en yüksek oranlar bizde. 1xbet",
        "Sweet Bonanza'da 100 FS hediye, ilk yatırımına özel",
        "fr3esp1n kazan, b0nus kodu: VIP50 → kazanbahis.site",
        "Bugune ozel freebet 200 TL. Uye ol, aninda cekim!",
        "Curacao lisanslı sitemizde limitsiz çekim. Giriş: cutt.ly/abc",
        "Welcome bonus 200% + free spins at our online casino"
    ])
    func filtersBetMessages(message: String) {
        let verdict = classifier.classify(body: message, sender: "+905321234567")
        #expect(verdict.isJunk, "Score \(verdict.score): \(verdict.signals.map(\.detail))")
    }

    @Test("Still filters on the relaxed setting when the evidence is strong")
    func relaxedStillFiltersStrongMessages() {
        let relaxed = BetClassifier(settings: FilterSettings(strictness: .relaxed))
        let verdict = relaxed.classify(body: "Deneme bonusu 500 TL! Hemen giriş: bit.ly/3xYz", sender: nil)
        #expect(verdict.isJunk)
    }

    @Test("A term inside a longer matching term is not counted twice")
    func overlappingTermsCountOnce() {
        let verdict = classifier.classify(body: "Deneme bonusu çevrimsiz", sender: nil)
        let terms = verdict.signals.filter { $0.kind == .gamblingTerm }.map(\.detail)
        #expect(terms.sorted() == ["deneme bonusu", "çevrimsiz"].sorted())
    }

    // MARK: - Messages that must pass

    @Test("Lets ordinary messages through", arguments: [
        "Merhaba, akşam sohbet etmeye gelir misin?",
        "Garanti BBVA Bonus kartınıza 50 TL bonus yüklendi.",
        "Doğrulama kodunuz: 482913. Kimseyle paylaşmayın.",
        "Kargonuz yola çıktı, takip için: yurticikargo.com",
        "Toplantı slotu 14:00 olarak ayarlandı.",
        "Siparişiniz hazırlanıyor. Trendyol",
        "Rekabet kurumu kararı açıklandı.",
        "Betül doğum günün kutlu olsun! 🎂",
        "Muhabbet kuşu için mama aldım, 150 TL tuttu.",
        "e-Devlet şifreniz değiştirildi. turkiye.gov.tr",
        "Abonelik ücretiniz 99,90 TL olarak yansıtılacaktır.",
        "Beton dökümü yarın sabah 8'de."
    ])
    func allowsNormalMessages(message: String) {
        let verdict = classifier.classify(body: message, sender: "+905321234567")
        #expect(!verdict.isJunk, "Score \(verdict.score): \(verdict.signals.map(\.detail))")
    }

    @Test("A link alone never filters a message")
    func linkAloneIsNotEnough() {
        let verdict = classifier.classify(body: "Fotoğrafları buraya yükledim: bit.ly/tatil2026", sender: "05321234567")
        #expect(!verdict.isJunk)
        #expect(verdict.score == 0)
    }

    // MARK: - User rules

    @Test("Blocked words always filter")
    func blockedWord() {
        let settings = FilterSettings(userRules: UserRules(blockedWords: ["kampanya"]))
        let verdict = BetClassifier(settings: settings).classify(body: "Büyük KAMPANYA başladı", sender: nil)
        #expect(verdict.isJunk)
        #expect(verdict.signals.first?.kind == .userBlockedWord)
    }

    @Test("Allowed senders always pass")
    func allowedSender() {
        let settings = FilterSettings(userRules: UserRules(allowedSenders: ["0532 123 45 67"]))
        let verdict = BetClassifier(settings: settings).classify(body: "Deneme bonusu 500 TL", sender: "+905321234567")
        #expect(!verdict.isJunk)
        #expect(verdict.signals.first?.kind == .userAllowedSender)
    }

    @Test("Blocked senders match whatever the number format")
    func blockedSenderFormats() {
        let settings = FilterSettings(userRules: UserRules(blockedSenders: ["+90 532 123 45 67"]))
        let verdict = BetClassifier(settings: settings).classify(body: "Selam", sender: "05321234567")
        #expect(verdict.isJunk)
    }

    @Test("Allowed words win over gambling terms")
    func allowedWord() {
        let settings = FilterSettings(userRules: UserRules(allowedWords: ["poker gecesi"]))
        let verdict = BetClassifier(settings: settings).classify(body: "Cuma poker gecesi bizde, casino temalı!", sender: nil)
        #expect(!verdict.isJunk)
    }

    // MARK: - Links

    @Test("Finds disguised links")
    func disguisedLinks() {
        let rules = CompiledRules.builtIn
        let hosts = LinkScanner.links(in: "giris: betxyz [.] com ve site nokta net", knownTopLevelDomains: rules.knownTopLevelDomains)
            .map(\.host)
        #expect(hosts.contains("betxyz.com"))
        #expect(hosts.contains("site.net"))
    }

    @Test("Does not mistake sentences for links")
    func sentencesAreNotLinks() {
        let rules = CompiledRules.builtIn
        let hosts = LinkScanner.links(in: "kazandin.hemen gel. saat 14.30", knownTopLevelDomains: rules.knownTopLevelDomains)
        #expect(hosts.isEmpty)
    }
}

@Suite("Shared store")
struct SharedStoreTests {
    @Test("Saves and loads settings")
    func roundTrip() {
        let store = SharedStore(suiteName: "RedCardCoreTests.\(UUID().uuidString)")
        let settings = FilterSettings(strictness: .strict, userRules: UserRules(blockedWords: ["test"]))
        store.save(settings)
        #expect(store.load() == settings)
    }
}

import Foundation
