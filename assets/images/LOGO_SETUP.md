# 🎨 Logo Kurulumu

## ✅ Yapılanlar:

1. ✅ Splash screen widget'ı logoyu gösterecek şekilde güncellendi
2. ✅ `flutter_launcher_icons` paketi eklendi ve yapılandırıldı
3. ✅ Native splash screen yapılandırması hazır

## 📝 Şimdi Yapmanız Gerekenler:

### 1️⃣ Logo Dosyalarını Ekleyin

**Gereksinimler:**
- Format: PNG
- Boyut: 1024x1024 px (önerilen, minimum 512x512)
- Arka plan: Şeffaf (transparent)
- İçerik: Beyaz şişe karakteri logosu

**Dosya Adları:**
1. `assets/images/splash_logo.png` - Splash screen için
2. `assets/images/app_icon.png` - Uygulama ikonu için

**Not:** Her iki dosya da aynı logo olabilir, ancak splash screen için daha büyük boyut önerilir.

### 2️⃣ Paketleri Yükleyin

```bash
flutter pub get
```

### 3️⃣ Uygulama İkonlarını Oluşturun

```bash
flutter pub run flutter_launcher_icons
```

Bu komut şunları yapacak:
- Android launcher icon'larını oluşturacak (tüm mipmap klasörleri)
- iOS app icon'larını oluşturacak
- Web icon'larını oluşturacak
- Windows ve macOS icon'larını oluşturacak

### 4️⃣ Native Splash Screen'i Oluşturun

```bash
flutter pub run flutter_native_splash:create
```

### 5️⃣ Uygulamayı Yeniden Build Edin

```bash
flutter clean
flutter run
```

## 🎨 Mevcut Ayarlar:

**Splash Screen:**
- Arka plan rengi: Cream (#F5F0E8)
- Logo pozisyon: Center
- Platformlar: Android + iOS

**App Icon:**
- Android: Tüm mipmap klasörleri için otomatik oluşturulacak
- iOS: AppIcon asset catalog için otomatik oluşturulacak
- Web: Background color: #F5F0E8, Theme color: #D97D45

## 🔧 Özelleştirme:

### Splash Screen:
`pubspec.yaml` dosyasındaki `flutter_native_splash` bölümünden:
- `color`: Arka plan rengini değiştirin
- `android_gravity`: Logo pozisyonunu ayarlayın (top, bottom, left, right, center, fill)
- `ios_content_mode`: iOS logo pozisyonunu ayarlayın

### App Icon:
`pubspec.yaml` dosyasındaki `flutter_launcher_icons` bölümünden:
- `image_path`: Logo dosyasının yolunu değiştirin
- `min_sdk_android`: Minimum Android SDK versiyonunu ayarlayın
- `background_color`: Web için arka plan rengi
- `theme_color`: Web için tema rengi

## 💡 Logo Hazırlama İpuçları:

1. **Şeffaf Arka Plan:** Logo PNG dosyasının arka planı şeffaf olmalı
2. **Kare Format:** Logo kare (1:1) oranında olmalı
3. **Yüksek Çözünürlük:** 1024x1024 px veya daha yüksek önerilir
4. **Temiz Tasarım:** Logo küçük boyutlarda da okunabilir olmalı

## 🚀 Test:

```bash
# Android Release
flutter run --release

# iOS Release
flutter run --release

# APK Build
flutter build apk --release

# iOS Build
flutter build ios --release
```

## ❓ Sorun Giderme:

**Logo görünmüyor:**
- Logo dosyasının `assets/images/` klasöründe olduğundan emin olun
- `pubspec.yaml`'daki `assets` bölümünde `assets/images/` tanımlı olmalı
- `flutter pub get` komutunu çalıştırın
- `flutter clean` ve `flutter run` yapın

**App icon değişmedi:**
- `flutter pub run flutter_launcher_icons` komutunu çalıştırdığınızdan emin olun
- Uygulamayı cihazdan tamamen silip yeniden yükleyin
- `flutter clean` yapın ve yeniden build edin

