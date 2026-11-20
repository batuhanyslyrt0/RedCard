#!/usr/bin/env python3
"""Writes RedCard/Localizable.xcstrings with the Turkish translations.

English is the source language; the keys below are the exact strings used in
the Swift code. Run from the project folder:  python3 Tools/make_strings.py
Afterwards Xcode keeps the catalog up to date; edit translations in Xcode.
"""
import json
import pathlib
import re
import sys

TR = {
    # Home
    "Red Card": "Red Card",
    "Try a message": "Mesaj dene",
    "Your rules": "Kuralların",
    "Strictness": "Hassasiyet",
    "Clean up old messages": "Eski mesajları temizle",
    "How Red Card works": "Red Card nasıl çalışır",
    "Bet messages stay out of your inbox.": "Bet mesajları artık gelen kutuna düşmez.",
    "Red Card checks texts from unknown senders on your iPhone and moves betting and casino adverts to Junk.":
        "Red Card, bilinmeyen numaralardan gelen SMS'leri iPhone'unda kontrol eder ve bahis ile casino reklamlarını Gereksiz klasörüne taşır.",
    "iOS doesn't tell apps whether the filter is on, so Red Card can't show it here. If bet messages reach your inbox again, check that Red Card is still chosen in Settings.":
        "iOS, filtrenin açık olup olmadığını uygulamalara bildirmiyor; bu yüzden Red Card bunu burada gösteremez. Bet mesajları yine gelen kutuna düşerse Ayarlar'da Red Card'ın hâlâ seçili olduğunu kontrol et.",
    "Check in Settings": "Ayarlar'da kontrol et",
    "Turn on the filter": "Filtreyi aç",
    "Relaxed": "Rahat",
    "Balanced": "Dengeli",
    "Strict": "Sıkı",
    "Only messages that are clearly betting adverts go to Junk. Choose this if a normal message was ever filtered by mistake.":
        "Sadece açıkça bahis reklamı olan mesajlar Gereksiz'e gider. Normal bir mesaj yanlışlıkla filtrelendiyse bunu seç.",
    "Recommended. Catches almost every bet message while leaving bank, cargo and code messages alone.":
        "Önerilen. Bet mesajlarının neredeyse hepsini yakalar; banka, kargo ve doğrulama kodu mesajlarına dokunmaz.",
    "Also catches messages with only a few betting signs. A normal message may occasionally end up in Junk.":
        "Az sayıda bahis işareti taşıyan mesajları da yakalar. Ara sıra normal bir mesaj Gereksiz'e düşebilir.",

    # Setup
    "Open the Settings app.": "Ayarlar uygulamasını aç.",
    "Scroll down and tap Apps, then Messages.": "Aşağı kaydır, Uygulamalar'a ve ardından Mesajlar'a dokun.",
    "Tap Unknown & Spam.": "Bilinmeyen ve Gereksiz'e dokun.",
    "Under SMS Filtering, choose Red Card.": "SMS Filtreleme altında Red Card'ı seç.",
    "Four steps in Settings": "Ayarlar'da dört adım",
    "The button below opens Red Card's page in Settings. Go back once to reach Apps.":
        "Aşağıdaki düğme Ayarlar'da Red Card sayfasını açar. Uygulamalar'a ulaşmak için bir kez geri git.",
    "Open Settings": "Ayarlar'ı aç",
    "Where filtered messages go": "Filtrelenen mesajlar nereye gider",
    "In Messages, tap Filters at the top left, then Junk. Filtered messages wait there without a notification.":
        "Mesajlar'da sol üstteki Filtreler'e, ardından Gereksiz'e dokun. Filtrelenen mesajlar orada bildirim göndermeden bekler.",
    "Messages from your contacts are never checked or filtered.":
        "Rehberindeki kişilerden gelen mesajlar asla kontrol edilmez ve filtrelenmez.",
    "Close": "Kapat",
    "It's on": "Açtım",

    # Tester
    "Paste or type a message": "Bir mesaj yapıştır veya yaz",
    "Sender (optional)": "Gönderen (isteğe bağlı)",
    "Message": "Mesaj",
    "For example +90 532 123 45 67. The sender helps a little, but the message text matters most.":
        "Örneğin +90 532 123 45 67. Gönderen biraz yardımcı olur ama asıl önemli olan mesajın metni.",
    "Why": "Neden",
    "Use a sample bet message": "Örnek bir bet mesajı kullan",
    "Goes to Junk": "Gereksiz'e gider",
    "Stays in your inbox": "Gelen kutunda kalır",
    "Score": "Puan",
    "Score %lld, filtered from %lld": "Puan %1$lld, filtre sınırı %2$lld",

    # Signals
    "Betting word “%@”": "Bahis kelimesi “%@”",
    "Betting brand name “%@”": "Bahis markası “%@”",
    "Link to a betting site: %@": "Bahis sitesi linki: %@",
    "Shortened link: %@": "Kısaltılmış link: %@",
    "Chat group invite: %@": "Sohbet grubu daveti: %@",
    "Unusual link: %@": "Şüpheli link: %@",
    "Link: %@": "Link: %@",
    "Money or bonus amount “%@”": "Para veya bonus miktarı “%@”",
    "Sent from a personal mobile number": "Bireysel bir cep numarasından gönderilmiş",
    "Sent from a foreign number": "Yurt dışı numarasından gönderilmiş",
    "Sent from an email address": "Bir e-posta adresinden gönderilmiş",
    "Sent under a registered company name": "Kayıtlı bir firma adıyla gönderilmiş",
    "Looks like an ordinary message: “%@”": "Normal bir mesaja benziyor: “%@”",
    "Matches your blocked word “%@”": "Engellediğin kelimeyle eşleşiyor: “%@”",
    "Sender is on your blocked list: %@": "Gönderen engel listende: %@",
    "Matches your allowed word “%@”": "İzin verdiğin kelimeyle eşleşiyor: “%@”",
    "Sender is on your allowed list: %@": "Gönderen izin listende: %@",

    # Rules
    "Add": "Ekle",
    "Always filter these words": "Bu kelimeleri her zaman filtrele",
    "Always filter these senders": "Bu gönderenleri her zaman filtrele",
    "Never filter these words": "Bu kelimeleri asla filtreleme",
    "Never filter these senders": "Bu gönderenleri asla filtreleme",
    "Add a word or phrase": "Kelime veya ifade ekle",
    "Add a phone number": "Telefon numarası ekle",
    "Any message containing one of these goes to Junk. Spelling tricks such as dots between letters are caught too.":
        "Bunlardan birini içeren her mesaj Gereksiz'e gider. Harflerin arasına nokta koymak gibi yazım hileleri de yakalanır.",
    "Numbers match in any format: 0532…, +90 532… and 532… are the same.":
        "Numaralar her biçimde eşleşir: 0532…, +90 532… ve 532… aynı kabul edilir.",
    "Messages containing one of these are never filtered, even if they look like betting.":
        "Bunlardan birini içeren mesajlar bahse benzese bile asla filtrelenmez.",
    "Use this for a number whose messages were filtered by mistake. Contacts never need adding: iOS doesn't send their messages to filters.":
        "Mesajları yanlışlıkla filtrelenen bir numara için bunu kullan. Rehberindeki kişileri eklemene gerek yok: iOS onların mesajlarını filtrelere hiç göndermez.",

    # Cleanup
    "Apple doesn't let any app read or delete messages already on your iPhone, so old bet messages need to be removed in Messages. These are the quickest ways.":
        "Apple, hiçbir uygulamanın iPhone'undaki mevcut mesajları okumasına veya silmesine izin vermez. Bu yüzden eski bet mesajlarını Mesajlar uygulamasından silmen gerekir. En hızlı yollar şunlar.",
    "On your iPhone, check that Messages in iCloud is on: Settings › your name › iCloud › Messages.":
        "iPhone'unda iCloud'da Mesajlar'ın açık olduğundan emin ol: Ayarlar › adın › iCloud › Mesajlar.",
    "Open Messages on a Mac signed in with the same Apple Account.":
        "Aynı Apple Hesabı ile giriş yapılmış bir Mac'te Mesajlar'ı aç.",
    "Hold Command and click each bet conversation, or click the first one and Shift-click the last.":
        "Command tuşunu basılı tutup her bet sohbetine tıkla ya da ilkine tıklayıp sonuncuya Shift ile tıkla.",
    "Press Delete. The conversations are removed from your iPhone too.":
        "Delete tuşuna bas. Sohbetler iPhone'undan da silinir.",
    "Fastest: with a Mac": "En hızlısı: Mac ile",
    "Hundreds of conversations can be selected and deleted at once this way.":
        "Bu yolla yüzlerce sohbeti tek seferde seçip silebilirsin.",
    "On iPhone": "iPhone'da",
    "Open Messages, tap Filters at the top left and choose Unknown Senders.":
        "Mesajlar'ı aç, sol üstteki Filtreler'e dokun ve Bilinmeyen Gönderenler'i seç.",
    "Tap the More button or Edit, then Select Messages.":
        "Diğer (⋯) düğmesine ya da Düzenle'ye, ardından Mesajları Seç'e dokun.",
    "Tap each bet conversation, then tap Delete.": "Her bet sohbetine dokun, ardından Sil'e dokun.",

    # About
    "Private by design": "Gizlilik en baştan",
    "Every message is checked on your iPhone. Red Card has no servers, no account and no tracking.":
        "Her mesaj iPhone'unda kontrol edilir. Red Card'ın sunucusu, hesabı ve takibi yoktur.",
    "The filter has no internet access and can't store anything, so your messages never leave your phone.":
        "Filtrenin internet erişimi yoktur ve hiçbir şey kaydedemez, yani mesajların telefonundan asla çıkmaz.",
    "What Red Card checks": "Red Card neyi kontrol eder",
    "SMS and MMS from numbers that aren't in your contacts.":
        "Rehberinde olmayan numaralardan gelen SMS ve MMS'ler.",
    "It looks for betting words, betting brand names, betting site links, bonus amounts and spelling tricks such as dots between letters.":
        "Bahis kelimelerine, bahis markalarına, bahis sitesi linklerine, bonus miktarlarına ve harflerin arasına nokta koymak gibi yazım hilelerine bakar.",
    "What iOS doesn't allow": "iOS'un izin vermedikleri",
    "Messages from your contacts and iMessages are never sent to filters.":
        "Rehberindeki kişilerden gelen mesajlar ve iMessage'lar filtrelere hiç gönderilmez.",
    "Filters can't delete messages or block numbers. Filtered messages wait in Junk, where you can still read them.":
        "Filtreler mesaj silemez ve numara engelleyemez. Filtrelenen mesajlar Gereksiz klasöründe bekler, istersen yine okuyabilirsin.",
    "Filters can't keep a count, so Red Card can't show how many messages it filtered.":
        "Filtreler sayım tutamaz, bu yüzden Red Card kaç mesaj filtrelediğini gösteremez.",
    "Red Card is free, with no ads and no in-app purchases.":
        "Red Card ücretsizdir; reklam ve uygulama içi satın alma yoktur.",
    "Version": "Sürüm",

    # Rule updates and shortcuts
    "Once a day the app may download an updated list of betting rules. Nothing about you or your messages is sent.":
        "Uygulama günde bir kez güncel bahis kuralları listesini indirebilir. Sen veya mesajların hakkında hiçbir şey gönderilmez.",
    "Rules version": "Kural sürümü",
    "Never filter this sender": "Bu göndereni asla filtreleme",
    "Always filter this sender": "Bu göndereni her zaman filtrele",
    "Wrong result?": "Sonuç yanlış mı?",
    "The sender is added to Your rules on this iPhone. You can remove it there at any time.":
        "Gönderen bu iPhone'daki Kuralların listesine eklenir. İstediğin zaman oradan kaldırabilirsin.",
}

root = pathlib.Path(__file__).resolve().parent.parent
sources = "\n".join(p.read_text() for p in (root / "RedCard").rglob("*.swift"))

# Every key must exist in the code (placeholders become interpolations).
missing = []
for key in TR:
    pattern = re.escape(key).replace(re.escape("%lld"), r"\\\([^)]*\)").replace(re.escape("%@"), r"\\\([^)]*\)")
    if not re.search(pattern, sources):
        missing.append(key)
if missing:
    print("Keys not found in Swift sources:", *missing, sep="\n  ")
    sys.exit(1)

catalog = {
    "sourceLanguage": "en",
    "strings": {
        key: {"localizations": {"tr": {"stringUnit": {"state": "translated", "value": value}}}}
        for key, value in sorted(TR.items())
    },
    "version": "1.0",
}
out = root / "RedCard" / "Localizable.xcstrings"
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
print(f"Wrote {len(TR)} strings to {out.relative_to(root)}")
