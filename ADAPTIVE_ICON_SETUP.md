# 🎨 Adaptive Icon ve Dark Mode Kurulumu

## ✅ Yapılanlar:

1. ✅ Android adaptive icon yapılandırması eklendi
2. ✅ Dark/Light mode için arka plan renkleri ayarlandı
3. ✅ Splash screen dark mode desteği eklendi
4. ✅ AndroidManifest.xml adaptive icon kullanacak şekilde güncellendi

## 📱 Yapılandırma Detayları:

### Android Adaptive Icon:
- **Light Mode:** Beyaz arka plan (#FFFFFF)
- **Dark Mode:** Siyah arka plan (#000000)
- **Foreground:** Logo resmi (app_icon.png)

### Splash Screen:
- **Light Mode:** Beyaz arka plan (#FFFFFF)
- **Dark Mode:** Siyah arka plan (#000000)
- **Logo:** Her iki modda da aynı logo kullanılıyor

## 🚀 Kurulum Adımları:

### 1️⃣ Logo Dosyalarını Kontrol Edin

Aşağıdaki dosyaların mevcut olduğundan emin olun:
- `assets/images/app_icon.png` (1024x1024 px, şeffaf arka plan)
- `assets/images/splash_logo.png` (1024x1024 px, şeffaf arka plan)

### 2️⃣ Paketleri Yükleyin

```bash
flutter pub get
```

### 3️⃣ Uygulama İkonlarını Oluşturun

```bash
flutter pub run flutter_launcher_icons
```

Bu komut:
- Android adaptive icon'ları oluşturacak
- `ic_launcher_foreground.png` dosyalarını tüm mipmap klasörlerine ekleyecek
- iOS app icon'larını oluşturacak

### 4️⃣ Native Splash Screen'i Oluşturun

```bash
flutter pub run flutter_native_splash:create
```

Bu komut:
- Light mode splash screen oluşturacak (beyaz arka plan)
- Dark mode splash screen oluşturacak (siyah arka plan)
- Android ve iOS için gerekli dosyaları oluşturacak

### 5️⃣ Uygulamayı Temizleyin ve Yeniden Build Edin

```bash
flutter clean
flutter run
```

## 📂 Oluşturulan Dosyalar:

### Android:
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `android/app/src/main/res/values/colors.xml` (light mode - beyaz)
- `android/app/src/main/res/values-night/colors.xml` (dark mode - siyah)
- Tüm mipmap klasörlerinde `ic_launcher_foreground.png` dosyaları

### iOS:
- Splash screen dosyaları otomatik oluşturulacak
- Dark mode desteği otomatik yönetiliyor

## 🎨 Nasıl Çalışıyor?

### Android Adaptive Icon:
1. Sistem dark mode'u algıladığında `values-night/colors.xml` dosyasındaki siyah rengi kullanır
2. Light mode'da `values/colors.xml` dosyasındaki beyaz rengi kullanır
3. Logo (foreground) her iki modda da aynı kalır

### Splash Screen:
1. `flutter_native_splash` paketi dark mode algılaması yapar
2. Light mode: Beyaz arka plan + logo
3. Dark mode: Siyah arka plan + logo

## 🔧 Özelleştirme:

### Arka Plan Renklerini Değiştirmek:

**Android Icon:**
- Light mode: `android/app/src/main/res/values/colors.xml`
- Dark mode: `android/app/src/main/res/values-night/colors.xml`

**Splash Screen:**
- `pubspec.yaml` dosyasındaki `flutter_native_splash` bölümünden:
  - `color`: Light mode arka plan rengi
  - `color_dark`: Dark mode arka plan rengi

## ⚠️ Önemli Notlar:

1. **Uygulamayı Cihazdan Silin:** Değişikliklerin görünmesi için uygulamayı cihazdan tamamen kaldırıp yeniden yükleyin
2. **Build Cache:** `flutter clean` komutunu mutlaka çalıştırın
3. **Android 8.0+:** Adaptive icon desteği Android 8.0 (API 26) ve üzeri için geçerlidir
4. **iOS 13+:** Dark mode desteği iOS 13 ve üzeri için geçerlidir

## 🧪 Test:

```bash
# Android Release Build
flutter build apk --release
flutter install

# iOS Release Build (macOS gerekli)
flutter build ios --release
```

Cihazınızın dark/light mode'unu değiştirerek test edin:
- **Android:** Ayarlar > Ekran > Karanlık tema
- **iOS:** Ayarlar > Ekran ve Parlaklık > Karanlık

## ❓ Sorun Giderme:

**Icon değişmedi:**
- Uygulamayı cihazdan tamamen silin
- `flutter clean` yapın
- `flutter pub run flutter_launcher_icons` komutunu tekrar çalıştırın
- Yeniden build edin

**Splash screen dark mode çalışmıyor:**
- `flutter pub run flutter_native_splash:create` komutunu tekrar çalıştırın
- Cihazın dark mode ayarını kontrol edin
- Uygulamayı yeniden başlatın



