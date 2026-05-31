# Release Readiness

Last audited: 2026-05-30.

## Current Status

Not live-ready.

The app has useful local-first product functionality, but Android release build,
release signing, and test coverage need work before a public launch.

## Verification Baseline

```text
flutter analyze
Result: passes with no issues.
```

```text
flutter test
Result: passes.
```

Important: the only test is `test/widget_test.dart`, which contains a disabled
placeholder assertion. This is not meaningful release coverage.

```text
flutter build apk --release
Result: fails.
```

First failure:

- dynamic `IconData(...)` calls block icon tree shaking.

```text
flutter build apk --release --no-tree-shake-icons
Result: fails.
```

Resolved follow-up:

- `home_widget` pulls AndroidX Glance/remote dependencies requiring compileSdk
  37 and Android Gradle Plugin 9.1.0+.
- Home widget support is disabled for v1 so the dependency no longer blocks
  release verification.

## P0 Release Blockers

1. Re-run a controlled release build for final verification.
2. Configure real release signing.
3. Keep auth strategy local-only, or implement real sign-in.
4. Decide whether to keep/remove the unused affirmation Hive repository path.
5. Add meaningful tests around storage/provider/release-critical flows.

## P1 Release Risks

- Notifications use fixed `Europe/Istanbul` timezone.
- iOS has microphone and speech recognition usage text.
- Voice command start-timer path only shows a success message and does not start
  the actual timer.
- Home "AI Insight" card is static; the real analytics card is not wired into
  Home.
- Water all-time stats increment on add but undo/delete paths do not decrement.

## Release Decision

Recommended v1 direction: local-only.

That means:

- remove sign-in/sign-out language
- keep local profile editing
- hide premium/export until implemented
- make all persistence and privacy copy honest
- ship only after Android release build and core local flows are verified
