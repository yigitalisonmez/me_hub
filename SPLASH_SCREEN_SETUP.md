# 🎨 Splash Screen Kurulumu

## ✅ Yapılanlar:

1. ✅ `flutter_native_splash` package'ı eklendi
2. ✅ Splash screen configuration yapıldı (pubspec.yaml)
3. ✅ Assets klasörü oluşturuldu
4. ✅ Package yüklendi

## 🚀 Şimdi Yapmanız Gerekenler:

### 1️⃣ Logo Hazırlayın

**Gereksinimler:**
- Format: PNG
- Boyut: 1024x1024 px (önerilen)
- Arka plan: Şeffaf (transparent)
- İçerik: Uygulamanızın logosu

**Logo Seçenekleri:**
- Kendi logonuz varsa kullanın
- Online araçlarla oluşturun (Canva, Figma, Photopea)
- Basit bir emoji/icon kullanın (📋, ✅, 🎯, etc.)

### 2️⃣ Logo'yu Projeye Ekleyin

Logo dosyanızı şu yola koyun:
```
assets/images/splash_logo.png
```

### 3️⃣ Splash Screen'i Generate Edin

Terminal'de şu komutları çalıştırın:

```bash
# Splash screen dosyalarını oluştur
flutter pub run flutter_native_splash:create

# Veya kısa yolu:
dart run flutter_native_splash:create
```

### 4️⃣ Uygulamayı Yeniden Build Edin

```bash
# Temizle ve yeniden build et
flutter clean
flutter run

# APK build için:
flutter build apk --release
```

## 🎨 Mevcut Ayarlar:

**Arka Plan Rengi:** Cream (#F5F0E8)
**Logo Pozisyon:** Center
**Platformlar:** Android + iOS

## 🔧 Özelleştirme (İsteğe Bağlı):

`pubspec.yaml` dosyasındaki `flutter_native_splash` bölümünden değiştirebilirsiniz:

```yaml
flutter_native_splash:
  color: "#F5F0E8"  # Arka plan rengini değiştirin
  image: assets/images/splash_logo.png
  android_gravity: center  # top, bottom, left, right, fill
  ios_content_mode: center  # scaleToFill, scaleAspectFit, scaleAspectFill
```

## 💡 Hızlı Test:

Logo ekledikten ve generate komutunu çalıştırdıktan sonra:

```bash
# Release modda çalıştır (splash screen daha iyi görünür)
flutter run --release

# Hot reload çalışmaz, uygulamayı kapatıp tekrar açın
```

## ❌ Eski Splash Screen Kaldırıldı:

- ✅ Flutter'ın varsayılan beyaz/siyah splash screen kaldırıldı
- ✅ Android launch_background.xml temizlendi
- ✅ Native splash screen yapılandırması hazır

## 🎉 Sonuç:

Logo ekleyip generate komutunu çalıştırdıktan sonra:
- ✨ Uygulama açılırken kendi splash screen'iniz görünecek
- 🚀 Flutter logo'su ve siyah ekran gitmeyecek
- 🎨 Cream arka plan + logo ile modern görünüm

## 📝 Logo Bulamıyorsanız:

Geçici olarak basit bir icon kullanabilirsiniz. İşte bazı öneriler:
- 📋 Clipboard icon (routine/todo temasına uygun)
- ✅ Checkmark icon
- 🎯 Target icon
- 📝 Note icon

Online PNG converter'larla emoji'yi PNG'ye çevirebilirsiniz:
https://emoji.aranja.com/


