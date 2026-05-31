# App Startup

The startup path is centered in `lib/main.dart`.

## Startup Flow

1. Ensure Flutter bindings.
2. Preserve native splash.
3. Initialize Hive with `Hive.initFlutter()`.
4. Register Hive adapters.
5. Open/init local data sources and boxes.
6. Initialize notification service.
7. Check onboarding status with SharedPreferences.
8. Build `KoraApp`.
9. Wire repositories and providers using `MultiProvider`.
10. Show `OnboardingPage` or `MainScreen`.

## MainScreen

`MainScreen` currently hosts a two-page `PageView`:

- Home
- Profile

The bottom navigation is `GlassNavBar`. The center microphone opens the voice
command sheet.

## Change Checklist

- If adding a provider, register it in `KoraApp`.
- If adding a Hive adapter, register it before opening the box.
- If changing onboarding, verify SharedPreferences keys.
- If changing initial navigation, verify the home/profile PageView behavior.
