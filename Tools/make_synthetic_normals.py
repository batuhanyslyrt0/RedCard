#!/usr/bin/env python3
"""Generates made-up everyday personal SMS for the model's "normal" class.

The real training data only contains messages from senders the user never
replied to (mostly companies), so the model never saw ordinary messages
between people: sending money, sharing a link, meeting up. These templates
are invented, contain no real data, and keep the model from treating
"amount + short link" as betting on its own.

    python3 Tools/make_synthetic_normals.py > synthetic_normals.txt
"""
import random

random.seed(7)
names = ["kardeşim", "abi", "abla", "kanka", "hocam", "canım", "dostum", "annecim", "babacım", "Ayşe", "Mehmet", "Elif", "Can"]
amounts = ["50 TL", "120 TL", "250 TL", "500 TL", "750 TL", "1.000 TL", "1.500 TL", "2.000 TL", "3.500 TL", "300 lira", "400 lira"]
links = ["bit.ly/dekont1", "bit.ly/foto24", "t.ly/konum", "cutt.ly/davetiye", "maps.app.goo.gl/abc", "drive.google.com/x",
         "zoom.us/j/123", "meet.google.com/abc", "tinyurl.com/sunum", "photos.app.goo.gl/x", "wa.me/905321234567", "t.me/sinifgrubu"]
places = ["Kadıköy", "okul", "iş yeri", "AVM", "kafe", "sinema", "hastane", "eczane", "maç", "halı saha", "spor salonu"]
times = ["akşam 8'de", "yarın sabah", "cumartesi", "hafta sonu", "öğlen", "birazdan", "10 dakikaya", "pazar günü"]
templates = [
    "{n} {a} attım, dekont burada: {l}",
    "{n} {a} gönderdim, geldi mi?",
    "Hesabına {a} yatırdım {n}, bakar mısın",
    "{n} kira için {a} eksik kaldı, ayın 5inde atarım",
    "Fotoğrafları buraya yükledim: {l}",
    "Konumu atıyorum {n}: {l}",
    "Toplantı linki: {l} {t} başlıyoruz",
    "Davetiye linki {l} {t} bekliyoruz",
    "{n} {t} {p} buluşalım mı?",
    "{n} {p} önündeyim, gelince ara",
    "{t} {p} gidiyoruz, sen de gel",
    "Maç {t}, {p} da izleyelim mi {n}?",
    "Halı saha {t}, kişi başı {a}",
    "{n} yemek parası {a}, iban atıyorum",
    "Bugün çok yoruldum {n}, {t} konuşalım",
    "Sınav sonuçları açıklandı, {l} bak",
    "{n} doğum günün kutlu olsun, nice mutlu yıllara!",
    "Hediye aldım sana {n}, {t} vereceğim",
    "Kargo geldi mi {n}? Takip: {l}",
    "Annem {a} gönderdi, sana da {a} attım",
    "Kumbara doldu {n}, {a} birikmiş",
    "Telefonum bozuldu {n}, bu numaradan yaz",
    "Ödev dosyası: {l} {t} teslim",
    "{n} bu akşam {p} kampanya var, {a} indirim varmış",
    "Spor salonu üyeliği {a} oldu, beraber yazılalım mı?",
    "Bilet aldım {n}, kişi başı {a}, link: {l}",
    "Ders notlarını yükledim {n}: {l}",
    "{n} ödemeyi yaptım, {a} kaldı",
    "Kazandım {n}! Sınavı geçtim",
    "Şans dileriz {n}, {t} görüşmen var değil mi",
    "Oyun gecesi {t}, kutu oyunları getir {n}",
    "Çekilişte telefon çıktı bize {n}, inanamıyorum",
    "Yatırım hesabı açtım {n}, borsa öğreniyorum",
    "Bonusumu aldım bu ay {n}, yemek benden",
    "Prim yattı {n}, {a} fazla geldi",
]
out = set()
while len(out) < 420:
    t = random.choice(templates)
    out.add(t.format(n=random.choice(names), a=random.choice(amounts), l=random.choice(links),
                     p=random.choice(places), t=random.choice(times)))
for line in sorted(out):
    print(line)
