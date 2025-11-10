# Splash Logo Setup

## 📱 Splash Screen Logo Yönergeleri

Bu klasöre `splash_logo.png` adında bir logo dosyası koymanız gerekiyor.

### ✅ Logo Gereksinimleri:

**Boyut:**
- Minimum: 512x512 px
- Önerilen: 1024x1024 px veya daha yüksek

**Format:**
- PNG (şeffaf arka plan)
- Kare boyut (1:1 oran)

**İçerik:**
- Uygulamanızın logosu/ikonu
- Şeffaf arka plan (transparent background)
- Temiz, minimal tasarım

### 🎨 Renk Şeması:
- Background: Cream (#F5F0E8)
- Logo: Turuncu (#E07A34) veya koyu gri

### 📝 Adımlar:

1. Logo dosyanızı hazırlayın (1024x1024 px, PNG, transparent)
2. Dosyayı `assets/images/splash_logo.png` olarak kaydedin
3. Terminal'de şu komutu çalıştırın:
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```
4. Uygulamayı yeniden build edin:
   ```bash
   flutter clean
   flutter run
   ```

### 🔧 Özelleştirme:

`pubspec.yaml` dosyasındaki `flutter_native_splash` bölümünden:
- `color`: Arka plan rengini değiştirin
- `android_gravity` / `ios_content_mode`: Logo pozisyonunu ayarlayın

### 💡 Logo Yoksa:

Eğer henüz bir logonuz yoksa:
- Basit bir icon/emoji kullanabilirsiniz
- Online logo maker araçları kullanabilirsiniz (Canva, Figma, etc.)
- Font icon'lardan (Material Icons, Font Awesome) export edebilirsiniz

### 🚀 Test:

```bash
# Android
flutter run --release

# Build APK
flutter build apk --release
```

Artık uygulama açılırken Flutter'ın varsayılan beyaz ekranı yerine kendi splash screen'iniz görünecek!


