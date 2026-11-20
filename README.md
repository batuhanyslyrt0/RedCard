# Red Card

Türkçe bet / casino SMS'lerini **Gereksiz** klasörüne taşıyan ücretsiz bir iPhone uygulaması.
Her şey telefonda çalışır: sunucu yok, internet yok, mesajlar telefondan çıkmaz.

## Proje yapısı

| Klasör | İçerik |
|---|---|
| `Packages/RedCardCore` | Filtre motoru: metin normalleştirme, kurallar, puanlama. Hem uygulama hem extension kullanır. Testleri burada. |
| `RedCardFilter` | iOS'un her bilinmeyen SMS için çağırdığı Message Filter Extension |
| `RedCard` | Ana uygulama (SwiftUI): kurulum rehberi, mesaj deneme, kendi kuralların, hassasiyet, temizleme rehberi |
| `Config` | Entitlement dosyaları ve extension'ın Info.plist'i |
| `Tools` | İkon üretme (`MakeAppIcon.swift`) ve çeviri dosyası üretme (`make_strings.py`) |
| `Docs/Design.md` | Tasarım kararları |

## İlk çalıştırma

1. `RedCard.xcodeproj` dosyasını Xcode ile aç.
2. Sol üstte **RedCard** projesine tıkla. **RedCard** ve **RedCardFilter** hedeflerinin ikisinde de
   **Signing & Capabilities** sekmesinden **Team** olarak kendi geliştirici hesabını seç.
3. Aynı sekmede **App Groups** altında `group.com.batuhan.redcard` görünmeli. Kırmızıysa yanındaki
   yenile düğmesine bas, Xcode grubu hesabına kaydeder.
4. iPhone'unu kabloyla bağla, üstten cihazını seç ve ▶︎ ile çalıştır.
   (SMS filtresi simülatörde test edilemez, çünkü simülatöre SMS gelmez.)
5. Telefonda: **Ayarlar › Uygulamalar › Mesajlar › Bilinmeyen ve Gereksiz › SMS Filtreleme › Red Card**.

> Bundle ID'yi değiştirmek istersen (`com.batuhan.redcard`), App Group'u da üç yerde aynı şekilde
> değiştir: iki `.entitlements` dosyası ve `SharedStore.swift` içindeki `appGroupIdentifier`.

## Filtre motorunun testleri

Xcode'a gerek kalmadan Terminal'den çalışır:

```bash
cd Packages/RedCardCore && swift test
```

Yeni bir bet mesajı kaçarsa, `ClassifierTests.swift` içindeki `filtersBetMessages` listesine ekle,
`DefaultRules.swift`'te kuralı güncelle ve testleri tekrar çalıştır.

## Bilinen iOS sınırları

- Sadece rehberde olmayan numaralardan gelen SMS/MMS filtrelenir; iMessage filtrelenmez.
- Filtre mesaj silemez, numara engelleyemez ve sayım tutamaz.
- Telefondaki eski mesajlara hiçbir uygulama erişemez (uygulamadaki "Eski mesajları temizle" rehberine bak).
