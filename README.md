# Red Card

Türkçe bet / casino SMS'lerini **İstenmeyen** klasörüne taşıyan ücretsiz, açık kaynak bir iPhone uygulaması.
Filtre tamamen telefonda çalışır: internet yok, kayıt yok. Telefondan çıkan tek şey, kullanıcının
Mesajlar'dan **kendisinin bildirdiği** kaçan bir mesajın metnidir (numara ve kimlik bilgisi olmadan).

## Proje yapısı

| Klasör | İçerik |
|---|---|
| `Packages/RedCardCore` | Filtre motoru: metin normalleştirme, kurallar, link tarayıcı, puanlama, bildirim içeriği. Üç hedef de kullanır. Testleri burada. |
| `RedCardFilter` | iOS'un her bilinmeyen SMS için çağırdığı Message Filter Extension |
| `RedCardReport` | Mesajlar'da "Bildir" ekranı (Unwanted Communication Reporting extension) |
| `RedCard` | Ana uygulama (SwiftUI): açılış animasyonu, kurulum rehberi, mesaj deneme, kendi kuralların, hassasiyet, temizleme rehberi |
| `Config` | Entitlement dosyaları ve extension'ların Info.plist'leri |
| `Rules/rules.json` | Yayınlanan kural listesi (uygulamalar günde bir kez indirir) |
| `Server` | `redcard.batudev.com`: bildirim alıcı servis (Node.js, bağımlılıksız), nginx ayarı, gizlilik sayfası, Apple doğrulama dosyası |
| `Tools` | İkon üretme, çeviri dosyası üretme, App Store ekran görüntüleri |
| `Docs` | Tasarım kararları ve App Store metinleri |

## İlk çalıştırma

1. `RedCard.xcodeproj` dosyasını Xcode ile aç.
2. **RedCard**, **RedCardFilter** ve **RedCardReport** hedeflerinin üçünde de **Signing & Capabilities › Team** olarak
   geliştirici hesabını seç (şu an `CUW625DYY8`).
3. iPhone'u bağla (Geliştirici Modu açık olmalı), cihazı seç ve ▶︎ ile çalıştır.
   SMS filtresi simülatörde test edilemez.
4. Telefonda: **Ayarlar › Uygulamalar › Mesajlar › Bilinmeyen ve İstenmeyen › Mesaj Filtresi › Red Card**.

> Bundle ID (`com.batuhan.redcard`) değişirse App Group'u (`group.com.batuhan.redcard`) üç entitlement dosyasında ve
> `SharedStore.swift`'te, Apple doğrulama dosyasındaki uygulama kimliklerini de `Server/public/.well-known/` altında güncelle.

## Testler

```bash
cd Packages/RedCardCore && swift test
```

## Kuralları güncellemek (uygulama güncellemesi olmadan)

1. `DefaultRules.swift`'i düzenle ve `version`'ı bir artır.
2. Kaçan mesajı `ClassifierTests.swift`'teki listeye ekle, `swift test` ile doğrula.
3. `cd Packages/RedCardCore && swift run export-rules > ../../Rules/rules.json`
4. `Server/deploy.sh` ile sunucuya yükle. Uygulamalar bir gün içinde yeni kuralları kullanır.

Bildirilen mesajları görmek için sunucuda:

```bash
ssh root@185.187.170.33 "cd /var/www/redcard.batudev.com && node tools/report-stats.js --missed"
```

## Sunucu (redcard.batudev.com)

İlk kurulum bir kez yapılır:

1. Natro DNS'te `redcard` için **A kaydı** → `185.187.170.33`.
2. `Server/deploy.sh` (dosyaları yükler, `redcard` PM2 servisini 3200 portunda başlatır).
3. Sunucuda nginx ayarını etkinleştir ve HTTPS al:
   ```bash
   ssh root@185.187.170.33
   mv /etc/nginx/sites-available/redcard.batudev.com.conf.new /etc/nginx/sites-available/redcard.batudev.com.conf
   ln -s /etc/nginx/sites-available/redcard.batudev.com.conf /etc/nginx/sites-enabled/
   nginx -t && systemctl reload nginx
   certbot --nginx -d redcard.batudev.com
   ```

## App Store ekran görüntüleri

```bash
Tools/screenshots.sh
```

## Bilinen iOS sınırları

- Sadece rehberde olmayan numaralardan gelen SMS/MMS filtrelenir; iMessage filtrelenmez.
- Filtre mesaj silemez, numara engelleyemez, sayım tutamaz ve açık olup olmadığı uygulamaya bildirilmez.
- Telefondaki eski mesajlara hiçbir uygulama erişemez (uygulamadaki "Eski mesajları temizle" rehberine bak).
