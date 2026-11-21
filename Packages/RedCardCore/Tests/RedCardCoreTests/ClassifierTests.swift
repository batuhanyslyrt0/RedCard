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

    // MARK: - Real messages that got through

    @Test("Real bet SMS that avoided every betting word (2026-11-21)")
    func ronaldoBonusMessage() {
        let body = "Galatasaray Ronaldoyu aldi B004\n\n\n\n\nRonaldo Kadar Buyuk bir Bns\n7200 lira otomatk tum Uyelere\n\n\nsmsat.vip/rnldgs"
        let verdict = classifier.classify(body: body, sender: "+84 1992692779")
        #expect(verdict.isJunk, "Score \(verdict.score): \(verdict.signals.map(\.detail))")
        // It must also be caught without the sender, on the text alone.
        #expect(classifier.classify(body: body, sender: nil).isJunk)
    }

    @Test("Real bet SMS sent under company-style sender IDs", arguments: [
        ("Bin Lira Hesabinda\nHemen Cekebilirsin.\nFenerbahce macinda her gole bizden 25Spn Hediye\n\nhttps://dub.mn/girisyapege B052", "TEKSOYINSTC"),
        ("Levantta her gun ozel oran var! Bugunun ozel oranini gormek icin tikla: https://bit.ly/altinorann B052", "TEKSOYMADTC"),
        ("TEBRIKLER! 5000TL KAZANDINIZ\n27 MILYON TL YILBASI CEKILISI SIZE OZEL VIP HEDIYELER SINIRSIZ CEKIM VE VIP TEMSILCINIZ\nDetaylar: https://t.ly/ovisvip udiS B064", "ERKEKLERHRF"),
        ("1000TL Ruzgari Ege den esiyor...\nGalatasaray macinda her gole bizden 25Spn Hediye\n10TL Yatir,30Milyon Hemen Cek.\n\nkslt.vip/GirisEge B052", "TEKSOYESYA"),
        ("Degerli Uyemiz,\n1.000TL bdv Nakt kazndin,hesabna eklendi\n\n1.000TLl lik yatrimina 50Spn ucretsz\n30Milyn cekm\n\n4sms.vip/pusulada ZCeI B064", "MRDINSAT"),
        ("2.000 TL YATIR, CEVRIMSIZ & CEKIM LIMITSIZ 4.000 TL ILE OYUNA BASLA! KAT KURALSIZ SINIRSIZ KAZANC MOJO'DA SENI BEKLIYOR!\n\nGuncel Giris: ggc.site/MOJO B052", "ESLEMREKL")
    ])
    func companyStyleBetSenders(message: String, sender: String) {
        let verdict = classifier.classify(body: message, sender: sender)
        #expect(verdict.isJunk, "Score \(verdict.score): \(verdict.signals.map(\.detail))")
    }

    @Test("Real company adverts that once looked like bet brands", arguments: [
        ("11.11 İNDİRİMLERİ BAŞLADI! Nike, adidas, New Balance ve daha birçok markada sepette %50'ye varan indirimler seni bekliyor. Link: https://ern.onl/abc", "INTERSPORT"),
        ("%60'a varan indirime ek 250 TL hediye! Yunan Adalari icin BiletFriday firsati! bilet.com/lnk/E41LRYB SMS ret:strw.me/?n=0", "BILET.COM"),
        ("Is Plus programinda Lacivert seviyede oldugunuz icin IsCepten yapacaginiz aylik sinirsiz sayida havale isleminizin ucretsiz oldugunu biliyor muydunuz?", "IS BANKASI"),
        ("Türk milleti ilelebet payidar kalacaktir. 10 Kasım'da saygı ve özlemle anıyoruz.", "I.B.B."),
        ("%3,48den baslayan faiz oranlari ile Aninda Krediye IsCepten hemen basvurun.", "IS BANKASI"),
        ("Acele et 5000 TL kupon hesabında! Fırsatı yakala: https://ty.gl/coucat", "TRENDYOL")
    ])
    func realCompanyAdverts(message: String, sender: String) {
        for strictness in Strictness.allCases {
            let verdict = BetClassifier(settings: FilterSettings(strictness: strictness)).classify(body: message, sender: sender)
            #expect(!verdict.isJunk, "\(strictness) score \(verdict.score): \(verdict.signals.map(\.detail))")
        }
    }

    @Test("A leetspeak word counts as one brand, not two")
    func leetBrandCountsOnce() {
        let verdict = classifier.classify(body: "Bet1", sender: nil)
        #expect(verdict.signals.filter { $0.kind == .gamblingBrand }.count == 1)
    }

    @Test("Foreign sender + money + odd link is treated as an advert")
    func promotionPattern() {
        let verdict = classifier.classify(body: "Sana ozel 5000 TL hediye, hemen al: qwe482.top/x", sender: "+84 1992692779")
        #expect(verdict.isJunk, "Score \(verdict.score): \(verdict.signals.map(\.detail))")
        #expect(verdict.signals.contains { $0.kind == .promotionPattern })
    }

    @Test("The advert pattern never applies to Turkish numbers or companies", arguments: [
        ("Kardeşim 500 TL attım, dekont burada: bit.ly/dekont1", "+905321234567"),
        ("Tüm üyelerimize ücretsiz kargo! Kampanya: trendyol.com", "TRENDYOL"),
        ("Hesabınıza 7.200 TL yatırıldı. Detay: qnb.com.tr", "QNB"),
        ("Hi, I sent you 50 USD, details: paypal.me/friend", "+14155550123"),
        ("Ronaldo Galatasaray'a transfer oldu, haberi gördün mü?", "+905321234567")
    ])
    func promotionPatternFalsePositives(message: String, sender: String) {
        let verdict = classifier.classify(body: message, sender: sender)
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
