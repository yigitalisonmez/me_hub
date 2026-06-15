# Release Readiness

Last audited: 2026-06-15.

> **Code side is release-ready for Android. Remaining gap is Play Console store
> work (listing, privacy policy hosting, data safety form), not code.**

## Current Status

Android release App Bundle (`.aab`) is built and signed. The app is local-only,
passes static analysis, and passes the full test suite. The notification
timezone bug is fixed. First release target is **Android-only**; iOS is deferred.

## Verification Baseline (2026-06-15)

```text
flutter analyze
Result: passes — no issues.
```

```text
flutter test
Result: passes — 114 tests (entity, provider, and widget tests).
```

```text
flutter build appbundle --release
Result: succeeds.
AAB: build/app/outputs/bundle/release/app-release.aab — 99.8 MB
Signing: kora-release.jks release signing config applied.
```

Size history: initial bundle was 183.5 MB. Removed 35 unused images
(~80 MB, including 17 dead 4K `profile_bg*.png` files) on 2026-06-15, dropping
the bundle to 99.8 MB. Remaining weight is mostly TFLite/audio/just_audio native
libs across ABIs; Play dynamic delivery splits these per-device, so the actual
user download is smaller than the bundle. Optional further wins: convert the 18
remaining in-use images (~11 MB) to WebP.

## Remaining Work Before Public Launch

### Play Console (not code — required to publish)

1. **Privacy policy URL** — draft written at `docs/PRIVACY-POLICY.md`. Must be
   hosted at a public URL and linked in the Play Console listing. Required
   because the app uses microphone, notifications, and internet.
2. **Play Console setup** — developer account, app entry, enable Play App
   Signing (upload key = `kora-release.jks`).
3. **Store listing assets** — 512×512 icon, 1024×500 feature graphic, phone
   screenshots, short/long description.
4. **Data Safety form + content rating** — declare microphone/internet usage
   honestly (no analytics, no data collection server-side).

### Code (deferred — ship via updates, not blocking)

1. **Affirmation Hive repository** — data-layer Hive repository (typeId 12) is
   registered but never called by the active provider flow. Decide: keep,
   migrate, or remove.
2. **Voice command stubs** — several parsed command types return a silent no-op
   instead of surfacing an "unsupported" message to the user.
3. **iOS signing** — not configured. Out of scope for Android-first v1.

## P1 Risks

- `AnalysisCard` (Pearson correlation, mood × water) is built but not wired to
  any screen. Home uses a static Daily Tip card.
- Voice commands have no confirmation step before executing actions.
- `MoodLocalDataSource.init()` previously deleted the box on any open failure.
  Fix applied (2026-06-01): now narrows to `HiveError` only and creates a
  backup before deleting.

## Resolved Blockers

All resolved on 2026-05-30.

### Release APK Did Not Build

Fixed:
- Dynamic `IconData(...)` reconstruction replaced with stable icon lookup
  mappings in breathing and challenges.
- `home_widget` dependency removed for v1 (runtime service is a no-op stub).

### Release Signing Was Debug

Fixed:
- Keystore generated: `android/kora-release.jks` (alias: kora, CN=Yigit).
- `android/key.properties` created and gitignored.
- `android/app/build.gradle.kts` reads `key.properties` and applies release
  signing; falls back to debug signing when the file is absent.

### Auth/Profile UI Was Misleading

Fixed:
- `lib/features/auth/` folders exist but are empty; profile is local-only.
- Fake fallback email, hardcoded Premium badge, coming-soon Export Data, and
  nonfunctional Sign Out were all removed from `ProfilePage`.

### Android Release Missing INTERNET Permission

Fixed:
- `android.permission.INTERNET` added to the main manifest for ZenQuotes API.

### Hive typeId Conflict

Fixed:
- `RoutineItem` and `AffirmationSession` both used typeId 10.
- `AffirmationSession` moved to typeId 12.
- Repository guards registration with `if (!Hive.isAdapterRegistered(12))`.

## Release Decision

Recommended v1 direction: local-only.

- No sign-in/sign-out language.
- Local profile editing only.
- Premium/export hidden until implemented.
- All persistence and privacy copy is honest.
