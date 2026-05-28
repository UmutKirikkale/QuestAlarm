# QuestAlarm — Oyun Editörü (Web)

Tarayıcıda açılan, sade arayüzlü içerik yönetim paneli.

## Hızlı başlangıç (yerel)

```bash
cd QuestAlarm
chmod +x scripts/run_admin_web.sh
./scripts/run_admin_web.sh
```

`run_admin_web.sh` varsayılan tarayıcıyı otomatik açar.

Veya doğrudan (Safari için en pratik):

```bash
flutter run -d web-server -t lib/admin_main.dart --web-port=7357
open -a Safari http://localhost:7357
```

Tarayıcıda **http://localhost:7357** (veya terminalde yazan port) açılır.

## Arayüz

- Sol menü (geniş ekran) veya alt menü (dar ekran): **Eşyalar · Sınıflar · Haritalar · Medya · Etkinlikler · Elmas IAP · God Mode · Canavarlar · Küresel**
- Geniş masaüstünde sağda **Canlı Akış** terminali (`live_logs`)
- Her sekmede: üstte **form kartı**, altta **kayıt listesi**
- Listede **kalem** = düzenle, **çöp kutusu** = sil
- Eşya/Harita formunda **Bilgisayardan görsel seç** ile dosyayı yükleyebilirsiniz

## Firebase (ilk kurulum)

1. [Firebase Console](https://console.firebase.google.com/) → proje **questalarm**
2. **Firestore Database** oluşturun (test modu geliştirme için yeterli)
3. **Proje ayarları** → **Uygulama ekle** → **Web** (`</>`)
4. Oluşan `appId` değerini `lib/firebase_options.dart` içindeki `web.appId` satırına yapıştırın

Web uygulaması eklenmeden Firestore bağlantısı hata verebilir.

## Görsel yükleme

- Admin panel seçtiğiniz resmi **Firebase Storage** içine yükler (`items/` veya `maps/`)
- Yükleme sonrası URL otomatik olarak ilgili görsel alanına yazılır ve Firestore'a kaydolur
- Mobil uygulama bu URL'leri doğrudan gösterebilir

**İlk kurulum (Storage hatası alıyorsanız):**

1. [Firebase Console](https://console.firebase.google.com/project/questalarm/storage) → **Storage** → **Get started** (bucket oluşturun — bu adım zorunlu)
2. **Rules** sekmesi → `storage.rules` dosyasının içeriğini yapıştırın → **Publish**
3. (İsteğe bağlı) **Authentication** → **Anonymous** → Enable
4. Admin panel üstündeki **Storage test** yeşil olmalı
5. Eşya formunda önce **eşya kodu** girin, sonra görsel seçin

Terminalden kuralları yayınlamak için: `firebase deploy --only storage` (`.firebaserc` projede tanımlı)

## Medya kütüphanesi

- **Medya** sekmesinde Storage görsellerini galeri olarak görebilirsiniz
- `Eşyalar` / `Haritalar` klasörleri arasında geçiş yapılır
- Her görsel için:
  - **URL**: bağlantıyı panoya kopyalar
  - **Sil**: Storage'dan kalıcı siler

## İnternete yayınlama (isteğe bağlı)

```bash
flutter build web -t lib/admin_main.dart --release
firebase deploy --only hosting
```

`firebase.json` hosting ayarları hazır (`build/web` klasörü).

## Koleksiyonlar

| Menü | Firestore |
|------|-----------|
| Eşyalar | `global_items` (`shopCurrency`: `gold` / `diamond`) |
| Sınıflar | `global_classes` |
| Haritalar | `global_maps` (`unlockPrice`, `shopCurrency`) |
| Etkinlikler | `global_events` |
| Elmas paketleri | `premium_packages` |
| God Mode | `users` (altın, elmas, streak, `isBanned`, envanter) |
| Canavarlar | `global_monsters` |
| Küresel | `global_settings/app` (`maintenanceMode`, `dailyQuestText`, ekonomi: `levelXpExponent`, `streakBonusPerDay`, `maxStreakMultiplier`, `repairCostPerDurability`) |
| Canlı terminal | `live_logs` (mobil yazar, admin dinler) |

Oyuncu etkinlik ilerlemesi: `users/{uid}/active_event_progress/{eventId}`

Mobil uygulama bu koleksiyonları canlı dinler. **Anlık LiveOps:** bakım/ban uygulama açıkken kilit ekranına düşürür; God Mode altın/elmas ana ekranda saniyede güncellenir; her savaş girişinde canavar havuzu Firestore'dan taze çekilir.
