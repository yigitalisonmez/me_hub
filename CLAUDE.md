# Kora Agent Guide

This file is the first context document for Claude/Codex-style agents working on
this repository. Keep it short, accurate, and updated when the project shape
changes.

## Project

Kora is a Flutter personal tracking app. It is local-first and currently uses:

- Flutter/Dart
- Provider for state management
- Hive, SharedPreferences, and FlutterSecureStorage for local data
- flutter_local_notifications and timezone for reminders
- speech_to_text plus a local TFLite NLP model for voice commands
- record and just_audio for affirmations/breathing audio flows
- home widget support is deferred; `home_widget` was removed for v1

## Commands

Run these from the repository root:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Notes:

- `flutter analyze` is expected to pass cleanly.
- Do not edit generated `*.g.dart` files manually.
- Run build_runner after changing Hive or json_serializable annotated models.

## Architecture

- App startup, Hive adapter registration, and provider wiring live in
  `lib/main.dart`.
- Shared app code lives in `lib/core/`.
- Product modules live in `lib/features/<feature>/`.
- Most mature features follow this shape:
  - `data/`
  - `domain/`
  - `presentation/`
- UI state is usually a `ChangeNotifier` provider.
- Persistence is mostly local. Prefer existing repository/data source patterns.

## Documentation Workflow

Use `docs/` as the Obsidian vault.

- Start with `docs/00-start-here.md`.
- Update `docs/02-architecture/*` when architecture, storage, or app flow
  changes.
- Update `docs/03-features/<feature>.md` when feature behavior changes.
- Track active work in `docs/05-tasks/active.md`.
- Write larger decisions as ADRs in `docs/04-decisions/`.

## Safety Rules

- Check `git status --short` before editing. The tree may contain user changes.
- Do not revert user changes unless explicitly asked.
- Do not manually change generated files.
- When adding Hive types, update `docs/02-architecture/hive-typeids.md`.
- When changing notifications, update `docs/02-architecture/notifications.md`.
- When changing voice/NLP behavior, update `docs/02-architecture/voice-and-nlp.md`.

## Current Hotspots

- This repository is not live-ready yet. Start with
  `docs/05-tasks/live-readiness-audit.md` before release work.
- Android release identity is now `com.yigit.kora`; release signing still uses
  the debug signing config until a real signing key is configured.
- The app is local-only today. There is no real sign-in/auth implementation.
- Android release manifest declares `INTERNET` because daily quote code calls
  ZenQuotes.
- Hive type IDs need strict tracking. The known routine/affirmation `typeId: 10`
  conflict was resolved by moving data-layer `AffirmationSession` to `12`.
- Automated tests are minimal; `test/widget_test.dart` is currently a placeholder.
- Calendar files were untracked when this documentation structure was created;
  check current git status before modifying them.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
