# Live Readiness Audit

Date: 2026-05-30

## Verdict

Do not ship yet.

The core product is promising and many local flows exist, but final release
build verification, real release signing, data integrity, and test coverage are
not ready.

## Commands Run

```text
git status --short
```

Observed existing modified/untracked files, including docs added during setup,
calendar feature files, and several app files already modified before this
audit.

```text
flutter analyze
```

Initial result: failed with 84 issues.

Latest result after P0 cleanup: passed with no issues.

```text
flutter test
```

Latest result: passed, but only because `test/widget_test.dart` is a
placeholder.

```text
flutter build apk --release
```

Initial result: failed because dynamic `IconData(...)` prevents icon tree
shaking.

Latest partial retry passed icon tree shaking and moved past the removed
`home_widget` dependency path, but the build was intentionally interrupted to
avoid overloading the development machine. No final release APK was produced in
that retry.

```text
flutter build apk --release --no-tree-shake-icons
```

Result: failed because AndroidX Glance/remote dependencies require compileSdk 37
and Android Gradle Plugin 9.1.0+, while the project uses compileSdk 36 and AGP
8.7.3.

## P0 Blockers

### P0-1: Release APK Does Not Build

Files:

- `lib/features/breathing/data/models/breathing_technique.dart`
- `lib/features/breathing/domain/entities/breathing_technique.dart`
- `lib/features/breathing/data/mappers/breathing_technique_mapper.dart`
- `lib/features/challenges/presentation/pages/challenges_page.dart`
- `lib/features/challenges/presentation/widgets/challenges_widgets.dart`
- `lib/features/challenges/presentation/utils/challenge_icon_lookup.dart`
- `pubspec.yaml`

Status:

- Fixed dynamic icon reconstruction by using stable icon mappings.
- Temporarily removed `home_widget` dependency for v1 and changed the runtime
  service to a no-op.
- Deleted the Android widget provider entry that depended on `home_widget`.

Remaining:

- Re-run a controlled release build when the machine can handle it, preferably
  only at final verification.

### P0-2: Release Signing Is Still Debug

Files:

- `android/app/build.gradle.kts`
- `ios/Runner.xcodeproj/project.pbxproj`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

Status:

- Product name is Kora.
- Android `applicationId` is `com.yigit.kora`.
- Android namespace is `com.yigit.kora`.
- iOS bundle ID is `com.yigit.kora`.

Remaining:

- Configure real release signing.

### P0-3: Auth/Profile UI Is Misleading

Files:

- `lib/features/auth/`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/profile/presentation/widgets/profile_widgets.dart`

Status:

- Auth folders are empty.
- Profile was moved to an honest local-only presentation.
- Fake fallback email `user@example.com` was removed.
- Hardcoded Premium badge/status was removed.
- Coming-soon Export Data action was removed.
- Nonfunctional Sign Out action was removed.

Remaining:

- Or implement real auth before shipping.

### P0-4: Android Release Missing INTERNET Permission

Files:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `lib/core/services/quote_service.dart`

Status:

- Fixed. `android.permission.INTERNET` was added to the main manifest because
  daily quotes use `https://zenquotes.io/api`.

### P0-5: Hive Type ID Conflict / Dead Affirmation Persistence Path

Files:

- `lib/features/routines/domain/entities/routine.dart`
- `lib/features/affirmations/data/models/affirmation_session.dart`
- `lib/features/affirmations/data/repositories/affirmation_repository.dart`
- `docs/02-architecture/hive-typeids.md`

Status:

- Fixed the concrete `typeId` conflict by moving data-layer
  `AffirmationSession` to `typeId: 12`.
- Current affirmation UI/provider does not appear to use the Hive repository
  path; it uses SharedPreferences and files.

Remaining:

- Decide whether to keep the Hive affirmation repository or remove/deprecate it
  if the SharedPreferences/file-backed provider is the intended v1 path.

### P0-6: Test Coverage Is Not Release-Meaningful

Files:

- `test/widget_test.dart`

Issue:

- Test suite passes but does not test real app behavior.

Next actions:

- Add provider/storage tests for Todo, Water, Mood, Routines, Calendar
  notification time calculation, and profile/local-only behavior.

## P1 Risks

- Voice command `startTimer` only shows success and does not start a timer.
- Internal package/repo names still include `me_hub`; user-facing product name
  is Kora.
- Home "AI Insight" is static while real analysis code exists elsewhere.
- Calendar feature is currently untracked in git status.
- `assets/krumzi-video.mp4` is untracked and not referenced by code/pubspec.
- Water all-time stats increment on add but undo/delete paths do not decrement,
  which can inflate profile stats.
- `home_widget` is intentionally disabled for v1 unless Android tooling is
  upgraded or the dependency is replaced.

## Recommended Execution Order

1. Configure real release signing.
3. Keep v1 auth strategy as local-only, or implement real auth before shipping.
4. Decide whether internal package/repo names should remain `me_hub`.
5. Keep iOS permission strings current if voice ships.
6. Decide whether to keep or remove the unused affirmation Hive repository.
7. Add meaningful tests.
8. Re-run tests and a controlled release build.
