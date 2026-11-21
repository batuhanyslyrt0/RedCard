import Foundation

extension RuleSet {
    /// The rules that ship inside the app.
    ///
    /// Terms are written in normal Turkish, because they are shown in the app.
    /// They go through the same normalizer as messages, so spelling variants
    /// such as `CEVRIMSIZ`, `Çevrimsiz` or `ç.e.v.r.i.m.s.i.z` all match.
    public static let builtIn = RuleSet(
        version: 2,
        terms: [
            // Bonus offers
            WeightedTerm("deneme bonusu", 60),
            WeightedTerm("deneme bonus", 60),
            WeightedTerm("yatırım bonusu", 55),
            WeightedTerm("yatırımsız bonus", 60),
            WeightedTerm("kayıp bonusu", 55),
            WeightedTerm("hoşgeldin bonusu", 45),
            WeightedTerm("hoş geldin bonusu", 45),
            WeightedTerm("ilk üyelik bonusu", 50),
            WeightedTerm("üyelik bonusu", 40),
            WeightedTerm("bedava bonus", 50),
            WeightedTerm("sınırsız bonus", 50),
            WeightedTerm("bonus kodu", 30),
            WeightedTerm("bonus", 15),
            // Shortened spellings used to dodge filters ("Bns", "Bnus")
            WeightedTerm("bns", 30),
            WeightedTerm("bnus", 30),
            WeightedTerm("bnsu", 30),
            WeightedTerm("çevrimsiz", 45),
            WeightedTerm("çevrim şartı", 40),
            WeightedTerm("çevrim şartsız", 45),
            WeightedTerm("çevrim", 15),
            WeightedTerm("kayıp iadesi", 30),
            WeightedTerm("cashback", 15),
            WeightedTerm("promosyon kodu", 15),

            // Spins and slot games
            WeightedTerm("freespin", 50),
            WeightedTerm("free spin", 50),
            WeightedTerm("bedava spin", 50),
            WeightedTerm("ücretsiz spin", 50),
            WeightedTerm("spin", 20),
            WeightedTerm("slot", 20),
            WeightedTerm("jackpot", 35),
            WeightedTerm("sweet bonanza", 50),
            WeightedTerm("gates of olympus", 50),
            WeightedTerm("big bass", 30),
            WeightedTerm("pragmatic play", 40),
            WeightedTerm("aviator", 25),
            WeightedTerm("maxwin", 40),
            WeightedTerm("max win", 35),

            // Betting and casino
            WeightedTerm("freebet", 50),
            WeightedTerm("free bet", 50),
            WeightedTerm("bedava bahis", 55),
            WeightedTerm("canlı bahis", 50),
            WeightedTerm("canlı casino", 50),
            WeightedTerm("online casino", 50),
            WeightedTerm("casino", 45),
            WeightedTerm("kumarhane", 45),
            WeightedTerm("kumar", 25),
            WeightedTerm("bahis", 35),
            WeightedTerm("iddaa", 30),
            WeightedTerm("rulet", 30),
            WeightedTerm("blackjack", 35),
            WeightedTerm("bakara", 30),
            WeightedTerm("baccarat", 35),
            WeightedTerm("poker", 20),
            WeightedTerm("yüksek oran", 30),
            WeightedTerm("en yüksek oran", 35),
            WeightedTerm("rakipsiz oran", 40),
            WeightedTerm("oranlar", 15),
            WeightedTerm("kombine", 20),
            WeightedTerm("kupon", 10),

            // Money in, money out
            WeightedTerm("anında çekim", 35),
            WeightedTerm("hızlı çekim", 30),
            WeightedTerm("limitsiz çekim", 40),
            WeightedTerm("çekim limiti", 25),
            WeightedTerm("ilk yatırım", 35),
            WeightedTerm("para yatır", 20),
            WeightedTerm("yatırım yap", 15),
            WeightedTerm("hemen kazan", 20),
            WeightedTerm("kazandınız", 15),
            WeightedTerm("kazanma şansı", 15),

            // "Our address changed" messages that push new mirror domains
            WeightedTerm("güncel giriş", 45),
            WeightedTerm("güncel adres", 40),
            WeightedTerm("giriş adresi", 40),
            WeightedTerm("yeni giriş adresi", 45),
            WeightedTerm("erişim adresi", 35),
            WeightedTerm("adresimiz değişti", 40),
            WeightedTerm("yeni adresimiz", 35),
            WeightedTerm("curacao", 35),
            WeightedTerm("lisanslı", 10),
            WeightedTerm("vip üyelik", 20),
            // How bet sites address their "members"
            WeightedTerm("tüm üyelere", 30),
            WeightedTerm("tüm üyelerimize", 30),
            WeightedTerm("üyelerimize özel", 30),
            WeightedTerm("yeni üyelere", 30),

            // English
            WeightedTerm("free spins", 50),
            WeightedTerm("deposit bonus", 50),
            WeightedTerm("no deposit", 40),
            WeightedTerm("welcome bonus", 40),
            WeightedTerm("betting", 35),
            WeightedTerm("sportsbook", 45),
            WeightedTerm("wager", 25)
        ],
        safeTerms: [
            // One-time codes and account security
            WeightedTerm("doğrulama kodu", -40),
            WeightedTerm("doğrulama kodunuz", -40),
            WeightedTerm("tek kullanımlık şifre", -40),
            WeightedTerm("şifreniz", -30),
            WeightedTerm("verification code", -40),
            WeightedTerm("e-devlet", -30),
            // Bank loyalty programmes that use the word "bonus"
            WeightedTerm("bonus kart", -35),
            WeightedTerm("bonus card", -35),
            WeightedTerm("bonusflaş", -35),
            WeightedTerm("bonus trink", -35),
            WeightedTerm("garanti bbva", -25),
            // Deliveries and appointments
            WeightedTerm("kargonuz", -20),
            WeightedTerm("siparişiniz", -15),
            WeightedTerm("randevunuz", -15)
        ],
        gamblingStems: ["bet", "bahis", "casino", "slot", "jackpot", "rulet", "poker", "iddaa", "kumar"],
        stemStoplist: [
            // Turkish words that contain "bet"
            "sohbet", "muhabbet", "rekabet", "nobet", "gurbet", "kurbet", "akibet",
            "musibet", "diyabet", "alfabe", "beton", "betim", "betik", "heybet",
            "nisbet", "mahabbet", "betul", "ubeyt", "tebessum",
            // English words that contain "bet"
            "better", "between", "betray", "beta", "alphabet", "abet", "diabet", "bethlehem"
        ],
        shortenerDomains: [
            "bit.ly", "t.ly", "tinyurl.com", "cutt.ly", "rb.gy", "is.gd", "v.gd",
            "shorturl.at", "rebrand.ly", "t.co", "goo.gl", "s.id", "tiny.cc",
            "ow.ly", "bl.ink", "shor.by", "urlz.fr", "linktr.ee", "tr.ee", "bitly.ws",
            "qrco.de", "u.to", "clck.ru", "lnk.bio"
        ],
        chatInviteDomains: ["t.me", "telegram.me", "wa.me", "chat.whatsapp.com"],
        suspiciousTopLevelDomains: [
            "xyz", "top", "club", "live", "vip", "win", "site", "online", "fun", "icu",
            "click", "link", "cc", "pw", "sbs", "cfd", "bond", "lat", "rest", "monster",
            "cyou", "buzz", "life", "today", "world", "space", "website", "pro", "ws", "to"
        ],
        // .vip and .win are used almost only by betting mirrors in Turkish SMS.
        gamblingTopLevelDomains: ["bet", "casino", "poker", "games", "bingo", "vip", "win"],
        trustedDomainSuffixes: ["gov.tr", "edu.tr", "bel.tr", "k12.tr", "tsk.tr", "pol.tr", "turkiye.gov.tr"],
        knownTopLevelDomains: [
            "com", "net", "org", "tr", "io", "co", "me", "ly", "gl", "at", "gd", "ee", "id",
            "info", "biz", "app", "store", "shop", "one", "gg", "tv", "us", "uk", "eu",
            "de", "ru", "in", "cloud", "tech", "fr", "cz", "az",
            "xyz", "top", "club", "live", "vip", "win", "site", "online", "fun", "icu",
            "click", "link", "cc", "pw", "sbs", "cfd", "bond", "lat", "rest", "monster",
            "cyou", "buzz", "life", "today", "world", "space", "website", "pro", "ws", "to",
            "bet", "casino", "poker", "games", "bingo", "bio"
        ]
    )
}
