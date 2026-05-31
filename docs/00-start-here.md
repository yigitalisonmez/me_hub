# Start Here

This folder is the Obsidian vault for Kora. It is the project memory for human
planning and AI-assisted development.

## How To Use This Vault

1. Read `../CLAUDE.md` first.
2. Read the architecture note that matches the work.
3. Read the feature note that matches the work.
4. Create or update an item in `05-tasks/active.md`.
5. After coding, record test results and update the relevant docs.

## Important Links

- Architecture overview: `02-architecture/overview.md`
- App startup: `02-architecture/app-startup.md`
- Data storage: `02-architecture/data-storage.md`
- Hive type IDs: `02-architecture/hive-typeids.md`
- Active tasks: `05-tasks/active.md`
- Backlog: `05-tasks/backlog.md`
- Done log: `05-tasks/done.md`

## Project Snapshot

Kora is a Flutter app for personal productivity and wellness. It combines daily
tasks, routines, water tracking, mood tracking, breathing, gratitude,
affirmations, challenges, calendar reminders, quotes, analytics, profile, and
voice commands.

The app is local-first. Data is stored mostly with Hive and SharedPreferences,
with some secure user data in FlutterSecureStorage.

## Current Baseline (Release Candidate State)

- Live-readiness audit: `05-tasks/live-readiness-audit.md`.
- Feature status matrix: `03-features/live-status.md`.
- `flutter analyze` passes with no issues.
- **46 Unit Tests** passing across core domains (Todo, Routines, Water).
- Final release build verified (`app-release.apk` signed and built successfully).
- Calendar and Routine background notifications verified on physical device.
- The app is local-only. No real sign-in/auth flow exists today.
- Keep the docs small but current. A short correct note is better than a long stale note.
