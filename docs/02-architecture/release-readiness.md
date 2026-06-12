# Release Readiness

Last audited: 2026-06-01.

> **Do not publish to Play Store until all items in "Remaining Work" are complete.**

## Current Status

Release build verified. The Android APK is built and signed. The app is
local-only and passes static analysis and the current test suite. Remaining
work before a public launch is documented below.

## Verification Baseline

```text
flutter analyze
Result: passes with no issues.
```

```text
flutter test
Result: passes — 46 tests.
```

Important: all 46 tests are entity-level unit tests. There are no provider,
repository, or widget integration tests. This is not meaningful release
coverage.

```text
flutter build apk --release
Result: succeeds (verified 2026-05-30).
APK: build/app/outputs/flutter-apk/app-release.apk — 204.5 MB
Signing: kora-release.jks, SHA-256 26aaae075f5d9b195808518f35817becaac16ad371fc1da188efcd152aaff21f
```

## Remaining Work Before Public Launch

1. **Notification timezone** — timezone was hardcoded to `Europe/Istanbul`.
   Fix in progress: reading device timezone via `flutter_timezone` at startup.
2. **Test coverage** — 46 entity-level unit tests exist. Provider, repository,
   and widget integration tests are needed before a public release is safe.
3. **Affirmation Hive repository** — the data-layer Hive repository for
   affirmations (typeId 12) is registered but never called by the active
   provider flow. Decide: keep, migrate, or remove.
4. **iOS signing** — not configured. If iOS v1 is in scope, Xcode signing
   and App Store provisioning must be set up first.
5. **Voice command stubs** — several parsed command types return a silent no-op
   instead of surfacing an "unsupported" message to the user.

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
