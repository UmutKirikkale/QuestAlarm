# QuestAlarm — En kolay kurulum (Flutter yok)

Bilgisayarda Flutter kurmadan APK üretip telefona yüklersiniz. Derleme **GitHub** sunucularında yapılır.

---

## 1. GitHub hesabı

https://github.com/signup → ücretsiz hesap açın.

---

## 2. GitHub Desktop (en kolay yükleme aracı)

1. İndir: https://desktop.github.com/
2. Kur → GitHub hesabınızla giriş yapın.

---

## 3. Projeyi GitHub’a gönder

1. GitHub Desktop → **File → Add local repository**
2. Klasör: `C:\Users\Digikey\Desktop\QuestAlarm`
3. “Bu klasör bir Git deposu değil” derse → **create a repository** deyin.
4. Summary: `QuestAlarm` → **Create repository**
5. **Publish repository** (veya **Push origin**)
   - İsterseniz **Keep this code private** işaretleyebilirsiniz.

---

## 4. APK’nın üretilmesini bekleyin

1. Tarayıcıda: `https://github.com/KULLANICI_ADINIZ/QuestAlarm`
2. Üst menü → **Actions**
3. **Build APK** işine tıklayın → yeşil tik olana kadar bekleyin (5–15 dk, ilk sefer).

Kırmızı hata olursa işe tıklayıp log’u kontrol edin veya yardım isteyin.

**Manuel tetikleme:** Actions → Build APK → **Run workflow**

---

## 5. APK’yı indirin

1. Tamamlanan **Build APK** işine tıklayın.
2. Aşağıda **Artifacts** → **QuestAlarm-apk** indirin.
3. ZIP’i açın → içindeki **`app-release.apk`** dosyasını alın.

---

## 6. Telefona yükleyin

1. `app-release.apk` dosyasını telefona atın (WhatsApp, Drive, kablo).
2. Dosyaya dokunun → **Yükle**.
3. Gerekirse: **Ayarlar → Güvenlik** → bilinmeyen uygulamalara izin.

---

## 7. İzinler (alarm için)

Uygulama açıldıktan sonra:

- **Bildirimler** → izin ver
- **Alarmlar ve hatırlatıcılar** (tam zamanlı alarm) → izin ver

Test: **Alarm Kur** → birkaç dakika sonrasını seçin.

---

## Kodu güncellediğinizde

GitHub Desktop → değişiklikleri **Commit** → **Push** → Actions yeni APK üretir → Artifact’tan tekrar indirin.

---

## Özet

| Adım | Ne yapıyorsunuz |
|------|------------------|
| 1–3 | GitHub + Desktop ile projeyi yükle |
| 4–5 | Actions’tan APK indir |
| 6–7 | Telefona yükle, izin ver |

Bilgisayarda **Flutter veya Android Studio gerekmez.**
