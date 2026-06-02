# PROJECT_STATE.md

Last updated: 2026-06-02 (ADR-002 Phase 3 — AnalysisCard wired to Home screen)  
Branch: main  
Build: release APK verified, signed (`android/kora-release.jks`)

---

## Product Summary

**Kora** is a local-first Flutter personal tracking app for Android (iOS configs exist but are not the release target for v1). It replaces multiple wellness and productivity apps with a single calm, private hub that requires no account and stores all data on the device.

**Core user questions the app answers daily:**
- What do I need to do today?
- How am I doing physically and emotionally?
- What habits am I building?
- What needs attention soon?

**Product pillars:** Daily clarity (tasks, routines, calendar, timer) · Wellness (water, mood, breathing) · Reflection (gratitude, affirmations) · Motivation (challenges, streaks, quotes) · Convenience (voice commands)

**Internal package name:** `me_hub`  
**Product name:** Kora  
**Bundle ID:** `com.yigit.kora`  
**v1 strategy:** Local-only. No accounts, no cloud sync, no export. Honest privacy story.

---

## Current Architecture

### Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter / Dart |
| State management | Provider (`ChangeNotifierProvider`) |
| Structured storage | Hive 2 |
| Settings / counters | SharedPreferences |
| Sensitive user data | FlutterSecureStorage |
| Notifications | flutter_local_notifications + timezone + flutter_timezone |
| Voice input | speech_to_text + TFLite (zen_flow_v2.tflite) |
| Audio recording | record + audio_waveforms |
| Audio playback | just_audio |
| HTTP | http (ZenQuotes API only) |
| Icons | lucide_icons_flutter |
| Fonts | google_fonts |

### Folder Layout

```
lib/
  main.dart                  ← 437-line startup + full MultiProvider wiring
  core/
    constants/
    errors/
    providers/               ← ThemeProvider, VoiceSettingsProvider
    services/                ← NotificationService, VoiceCommandService, QuoteService,
    │                           NlpIntentService, CommandParser, CumulativeStatsService,
    │                           CompletionTrackerService, QuoteCacheService
    theme/                   ← AppColors, AppTheme, ThemeExtensions, ElevationSystem
    utils/                   ← AppRoute, AppFadeRoute, Result, Validators
    widgets/                 ← Shared UI primitives (GlassNavBar, PageHeader,
                               ActionButton, StatCard, ProgressRing, …)
  features/
    <feature>/
      data/                  ← Models, Hive adapters, DataSources, RepositoryImpls
      domain/                ← Entities, Repository interfaces, UseCases
      presentation/          ← Providers (ChangeNotifier), Pages, Widgets
  shared/
    utils/                   ← DateUtils, StringUtils (pre-dates core/, do not add here)
    widgets/                 ← CustomButton, CustomTextField (pre-dates core/)
```

### Standard Data Flow

```
Widget → Provider → UseCase → Repository → DataSource → Hive / SharedPreferences
```

Not every feature implements the full stack — see the feature table below.

### Navigation

All pushes use `AppRoute` (fade + 4.5% slide-up, 300 ms). One-way replacements (onboarding → main) use `AppFadeRoute` (pure fade, 380 ms). Raw `MaterialPageRoute` is banned — 19 prior usages were replaced in the May 2026 redesign.

### App Startup Sequence (main.dart)

1. Ensure Flutter bindings, preserve native splash
2. Lock orientation to portrait
3. `Hive.initFlutter()` + register all adapters
4. Open / init all data sources and boxes
5. Init `NotificationService`
6. Check onboarding status via SharedPreferences
7. Build `KoraApp` with `MultiProvider`
8. Route to `OnboardingPage` or `MainScreen`

`MainScreen` hosts a `PageView` (Home / Profile) with `GlassNavBar`. The center mic button opens `VoiceCommandSheet`.

### Hive Type ID Registry

| Range | Domain |
|---|---|
| 0–9 | Todo + legacy |
| 10–19 | Routines + affirmations legacy (use with care) |
| 20–29 | Water |
| 30–39 | Mood |
| 40–49 | Gratitude |
| 50–59 | Challenges |
| 60–69 | Calendar |
| 70–79 | Profile / settings (reserved) |
| 80–89 | Analytics (reserved) |
| 90–99 | Future integrations (reserved) |

Full ID → type mapping lives in `docs/02-architecture/hive-typeids.md`.

---

## Current Features

### Working and tested

| Feature | Storage | Tests | Notes |
|---|---|---|---|
| **Todo** | Hive (typeId 0, 1) | 17 unit | Full data/domain/presentation stack. 6 use cases. |
| **Routines** | Hive (typeId 10, 11) | 18 unit | Streak logic, selected-days scheduling, notification integration. |
| **Water** | Hive (typeId 20, 21) | 11 unit | Daily goal, quick-add amounts, all-time stats with correct undo/delete decrement. |

### Working, not deeply tested

| Feature | Storage | Notes |
|---|---|---|
| **Mood Tracker** | Hive (typeId 30) | Daily mood + factors + notes. Heatmap, weekly trend. No use-case layer. Data source deletes box on open failure (data-loss risk). |
| **Gratitude** | Hive (typeId 40, 41, 42) | Entry + items + prompts. Streak tracking. Full stack. |
| **Calendar** | Hive (typeId 60–62) | Events, categories, reminder offsets. Background notifications verified on physical device. |
| **Challenges** | Hive (typeId 50–59) | Challenges, weekly goals, badges, user progress, streak freeze. Complex domain. Release icon tree-shaking fixed. |
| **Breathing** | SharedPreferences | Guided sessions, techniques, animation, mood check, background audio. Provider is 666 lines. Custom technique paths exist but are not fully surfaced in UI. |
| **Affirmations** | SharedPreferences + local files | Recording, playback, background sound, session flow (3-step PageView). Provider is 648 lines. |
| **Timer** | None (ephemeral) | Countdown timer, provider-only. No persistence. Voice "start timer" command is wired. |
| **Profile** | FlutterSecureStorage (user_name) | Local-only. Dynamic achievement carousel from ChallengesProvider. No auth. |
| **Settings** | SharedPreferences | Theme, voice language, notification prefs. Debug controls removed from user-facing screen. |
| **Onboarding** | SharedPreferences | Name + focus. Empty-name validation. Shows once. |

### Partially working

| Feature | Status |
|---|---|
| **Voice / NLP** | Mic → SpeechToText → TFLite intent → CommandParser. Some commands execute (add todo, start timer, log water). Many return "not implemented" silently. No command confirmation step. |
| **Quote** | ZenQuotes API + local cache. Requires INTERNET permission. No domain layer — single widget + two core services. |
| **Analytics** | `AnalysisService` (Pearson correlation, mood × water, mood by weekday, mood by time of day) is fully built. `AnalysisCard` is **live on the Home screen** below `InsightsCard` as of 2026-06-02. Card is invisible (`SizedBox.shrink()`) until ≥3 aligned mood + water days exist. No Provider wrapper — card manages its own async state directly. |

### Disabled / stub

| Feature | Status |
|---|---|
| **Home Widget** | `HomeWidgetService` is a no-op stub. Dependency removed for v1 to unblock release build. |
| **Auth** | `lib/features/auth/` exists but is empty. Profile is local-only. |
| **Data Export** | Hidden from UI until implemented. |
| **Premium / Entitlements** | Removed from Profile. No billing integration. |

---

## Open Issues

### P0 — Must resolve before next public release

All three original P0 items resolved on 2026-06-01. See `docs/05-tasks/done.md` for details.

| # | Issue | Status |
|---|---|---|
| P0-1 | `MoodLocalDataSource` silent data loss on any box-open failure | **Fixed** — narrowed to `HiveError`, backup + recovery flag added |
| P0-2 | Notification timezone hardcoded to `Europe/Istanbul` | **Fixed** — device timezone via `flutter_timezone`, UTC fallback |
| P0-3 | `release-readiness.md` said "build fails" — stale doc | **Fixed** — doc rewritten to reflect current state |

### P1 — Known gaps, not blocking current state

| # | Issue | Location |
|---|---|---|
| P1-1 | Voice commands with no implementation return a silent no-op. User gets false success feedback. | `lib/core/services/command_parser.dart` |
| P1-2 | `AnalysisService` bypasses Provider pattern — reads Hive boxes directly as a singleton. Intentional for v1; `AnalysisCard` is now live on Home screen. Wrapping in a Provider deferred to post-v1. | `lib/features/analytics/data/services/analysis_service.dart` |
| P1-3 | Affirmation `WelcomeStep` / `RecordStep` / `SessionStep` top bars may not fully match redesign spec (per active.md). | `lib/features/affirmations/presentation/widgets/` |
| P1-4 | Breathing `BreathingSessionPage` (active session screen) not audited against redesign. | `lib/features/breathing/presentation/pages/breathing_session_page.dart` |
| P1-5 | Mood `_TodayMoodCard` uses `Icon(level.icon)` — SVG face replacement was done for entry card, not verified in today card. | `lib/features/mood_tracker/presentation/pages/mood_page.dart` |
| P1-6 | Water/Todo cumulative stats have no tests for the provider-level edge cases (delete during same-day, undo after reload). | `test/features/` |

### Backlog (tracked in docs/05-tasks/backlog.md)

- Storage inventory: map every Hive box key and owning feature
- Tests: calendar reminder time calc, MoodLocalDataSource date-key behavior, smoke widget test with real providers
- Wire real `AnalysisCard` into Home, or promote the existing Daily Tip card
- Align Android namespace / iOS bundle ID (already matching, but namespace in Gradle not verified)
- Decide: keep or delete the dead affirmation Hive repository
- Home Widget: re-enable after choosing compatible dependency strategy

---

## Technical Debt

### Architecture

| Debt | Detail | Risk |
|---|---|---|
| `main.dart` is 437 lines | Manual wiring of every adapter, box, data source, use case, and provider inline. No DI framework. | High — grows linearly with every new feature |
| `breathing_provider.dart` is 666 lines | Timer, audio player, session state, custom techniques, and SharedPreferences access all in one class. | Medium — hard to test, easy to introduce regressions |
| `affirmation_provider.dart` is 648 lines | File I/O, audio recording, playback, SharedPreferences, and all UI state mixed. | Medium — same risk as breathing |
| Dead affirmation Hive repository | Domain + data layers built, Hive adapter registered (typeId 12), but the active provider never calls them. Two storage paths for the same feature. | Medium — schema ambiguity if someone re-activates the Hive path |
| `lib/shared/` vs `lib/core/` | 4 files in `shared/` predate the `core/` structure. No documented boundary. | Low — confusing for new agents/contributors |
| Analytics singleton | `AnalysisService` reads Hive directly, bypasses Provider. Not observable by UI. | Medium — needs a proper provider before it can ship |

### Testing

| Gap | Detail |
|---|---|
| No provider tests | All 46 tests are entity-level unit tests. No test exercises a provider with a mock data source. |
| No repository tests | No test verifies Hive read/write round-trips for any feature. |
| No widget/integration test | `test/widget_test.dart` is a renamed placeholder. |
| Covered features | Todo entities (17), Routine streak logic (18), WaterIntake model (11). |
| Uncovered features | Mood, Gratitude, Calendar, Challenges, Breathing, Affirmations, Voice/NLP, Analytics. |

### Minor

| Debt | Location |
|---|---|
| Turkish inline comment (`// Hive'ı başlat`) | `lib/main.dart:84` |
| Internal package/repo name `me_hub` diverges from product name `Kora` | `pubspec.yaml`, all import paths |
| `avoid_print` warnings not yet enforced in voice/NLP code | `lib/core/services/` |
| `ios/` signing is not configured | iOS release not planned for v1 but configs are present |

---

## Recommended Next Steps

Ordered by impact vs. effort. Does not include UI polish items (tracked in `docs/05-tasks/active.md`).

### Immediate (pre any new feature work)

~~1. Fix stale release-readiness doc.~~ **Done 2026-06-01.**  
~~2. Fix MoodLocalDataSource delete-on-failure.~~ **Done 2026-06-01.**  
~~3. Make timezone user-configurable.~~ **Done 2026-06-01** — device timezone via `flutter_timezone`.

### Short term (before next feature sprint)

4. **Decide the affirmation storage path.** Either delete the Hive domain/data layer for affirmations and document the SharedPreferences/file-backed path as canonical, or migrate the provider to use the Hive repository. The current split means two registered adapters and two diverging paths in the same feature.

5. **Add one provider-level integration test per core feature.** Priority order: MoodProvider (because of the data-loss risk), RoutinesProvider (notification scheduling logic), CalendarProvider (reminder time calculation). These do not need to spin up Hive — mock the data source.

6. **Reduce main.dart.** Extract Hive adapter registration into a dedicated function (e.g., `HiveSetup.registerAdapters()`), and data source initialisation into `AppDataSources.init()`. The `MultiProvider` widget list can stay in `main.dart` but should not also contain all the construction logic.

### Medium term (next feature cycle)

7. ~~**Wire AnalysisService into the UI.**~~ **Done 2026-06-02** — `AnalysisCard` placed on Home screen below `InsightsCard`. No Provider wrapper for v1 (intentional). If analytics data needs sharing across multiple widgets in future, add `ChangeNotifierProvider` then.

8. **Split large providers.** `BreathingProvider` (666 lines) and `AffirmationProvider` (648 lines) should each be split into a session-state provider and a settings/history provider. This makes them testable and reduces the risk of lifecycle bugs in audio/timer disposal.

9. **Smoke widget test.** Pump `KoraApp` with in-memory Hive + fake SharedPreferences and verify that the Home screen renders without error. This is the minimum meaningful regression guard for the full provider tree.

10. **Re-enable Home Widget.** Evaluate three options: upgrade AGP to 9.1+ and compileSdk to 37; replace `home_widget` with a lighter dependency; or write a native Android widget without the package. Option 2 (replace dependency) is likely the fastest unblocking path.

---

*This file is a point-in-time snapshot. Keep it updated when P0 issues are resolved, features change status, or architectural decisions are made.*
