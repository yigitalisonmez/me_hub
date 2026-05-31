# Done

Completed work should be summarized here with date, changed files, and test
results.

## 2026-05-31 (Post-Redesign Animation & Architecture Fixes)

**Mood page:**
- Scale buttons: removed continuous pulse (was causing full-page bounce). Now AnimatedContainer snap only (48→58px on select).
- Big orb: fixed layout shift — switched from variable `width/height` to `SizedBox(160×160)` + `Transform.scale`. Page no longer moves during pulse.
- Mood face icons: replaced all Lucide icons (frown/meh/smile/laugh/sparkles) with SVG face widget (`_MoodFaceWidget` via flutter_svg). Each mood has two eye circles + unique mouth path per design spec.

**Breathing page:**
- Orb centering: wrapped `_BreathingStage` in `SizedBox(width: double.infinity)` so orb centers across full screen.
- Vertical float: image now rises (`-4` → `-18px`) during inhale and descends on exhale — creates the organic "alive" breathing feel.
- Animation: `CurvedAnimation(easeInOut)`, 4s cycle (was 8s linear), scale 0.78→1.02.

**Affirmations architecture:**
- `AffirmationsPage` redesigned as standalone Daily Card (was broken: card + step indicator + pageview stacked together).
- New flow: "Sleep Affirmations" CTA button pushes `_SleepAffirmationsFlowPage` (separate `Navigator.push`).
- `_SleepAffirmationsFlowPage` manages the 3-step PageView (WelcomeStep → RecordStep → SessionStep) with pop-guard dialog.

**Calendar add-event sheet:**
- Full redesign: type selector (Task/Event/Routine), day-of-week repeat picker, reminder chips (At time/15 min/1 hour/1 day + live preview text), Add note collapsible row.

**`flutter analyze`:** passes cleanly.

## 2026-05-31 (Kora Redesign — Full UI Overhaul)

Comprehensive redesign of all major feature screens. Branch: `temp/kora-redesign-claude`, merged to `main`.

**Redesigned screens:**
- Affirmations: page + record/session/welcome step widgets
- Breathing: full page
- Calendar: full page
- Gratitude: full page
- Home: full page
- Mood Tracker: full page
- Onboarding: full page
- Profile: full page
- Routines: full page
- Timer: full page
- Todo: page + dashboard widgets
- Water: page, goal page (new), progress card, log section, quick-add section, amount button, log item

**New core widgets added:**
`action_button.dart`, `app_snack_bar.dart`, `progress_ring.dart`,
`section_header.dart`, `shimmer_loading.dart`, `stat_card.dart`

- `flutter analyze`: passes cleanly.
- `flutter test`: 46/46 tests passing.

## 2026-05-31 (Pre-Live UI Consistency Pass)

- Locked the app to portrait orientation via `SystemChrome.setPreferredOrientations`.
- Changed Home dashboard "Soon" feature tiles into a visibly disabled state with
  reduced opacity, passive overlay, and lock badge.
- Hardened `PageHeader` against long titles/subtitles and action/back-button
  overlap.
- Added a real Settings page shell with back navigation, cleaner preference
  layout, and wrapping voice-language chips.
- Aligned Water Settings with the shared page header and fixed primary-button
  text contrast.
- Polished Profile local-only copy, fixed the one-character-name avatar initials
  crash risk, and changed "Water Drinked" to "Water Logged".
- Removed no-op decorative header action icons from Mood and Routines.
- Capped long Home quote text so the hero card does not overflow.
- Relabelled the analytics card from "AI Insight" to "Mood Insight".
- `dart format`: completed for touched files.
- `flutter analyze`: no issues.
- `flutter test`: 46/46 tests passed.

## 2026-05-30

- Created the Obsidian/agent documentation structure.
- Added `CLAUDE.md` as the main agent guide.
- Added architecture, feature, task, prompt, and template notes.
- Ran initial live-readiness audit.
- Recorded release blockers in `05-tasks/live-readiness-audit.md`.
- Added feature status matrix in `03-features/live-status.md`.
- Fixed release-blocking dynamic icon reconstruction in breathing and challenges.
- Temporarily disabled `home_widget` for v1 because the current dependency path
  requires Android tooling not installed/configured locally.
- Added Android release `INTERNET` permission for network-backed daily quotes.
- Resolved the concrete Hive `typeId: 10` conflict by moving data-layer
  `AffirmationSession` to `typeId: 12`.
- Moved `flutter_native_splash` to runtime dependencies because app code imports
  it directly.
- Cleaned Profile for local-only v1: removed fake email, hardcoded Premium,
  Export Data coming-soon action, and nonfunctional Sign Out.
- Removed Settings debug/test notification controls from the user-facing screen.
- Set live product identity to Kora with Android/iOS bundle ID
  `com.yigit.kora`.
- Added iOS speech recognition permission text for voice commands.
- Reduced `flutter analyze` from 84 issues to a clean pass.
- Renamed the placeholder smoke test to Kora and confirmed `flutter test`
  passes.

## 2026-05-30 (Live Geçiş Düzeltmeleri)

- Fixed `pubspec.yaml` description from generic placeholder to a proper app description.
- Added `TimerProvider` to `MultiProvider` in `main.dart` (was missing from provider tree).
- Fixed voice command `startTimer`: now calls `TimerProvider.setMode + setCountdownDuration + start()` instead of just showing a success message.
- Guarded `_executeCommand` debug prints with `kDebugMode` in `voice_command_sheet.dart`.
- Added `CumulativeStatsService.subtractWater()` method for decrementing all-time stats.
- Fixed `WaterProvider.undoLastLog()`: now decrements cumulative all-time water stats.
- Fixed `WaterProvider.deleteLog()`: now decrements cumulative all-time water stats for the removed log.
- Updated `hive-typeids.md`: corrected AffirmationSession row to show typeId 12, renamed "Known Risk" to "Resolved Conflicts".
- Updated `active.md`: marked resolved decisions as done, kept only remaining blockers.
- `flutter analyze`: passes with no issues after all changes.

## 2026-05-30 (Release Signing + Final Build)

- Generated Android release keystore: `android/kora-release.jks`
  (alias: kora, CN=Yigit, OU=Kora, O=Kora, L=Istanbul).
- Created `android/key.properties` (gitignored) to pass signing credentials to Gradle.
- Updated `android/app/build.gradle.kts`: reads `key.properties` at build time and
  applies release signing config; falls back to debug signing when file is absent.
- Added `android/key.properties` and `android/*.jks` to `.gitignore`.
- Successfully built `build/app/outputs/flutter-apk/app-release.apk` (204.5 MB).
- Verified APK is signed with release key via `apksigner`:
  SHA-256: 26aaae075f5d9b195808518f35817becaac16ad371fc1da188efcd152aaff21f
- All P0 blockers are resolved. The app is ready for Google Play upload.

## 2026-05-30 (Post-Release Polish)

- Replaced static `InsightsCard` ("AI Insight") with a dynamic `Daily Tip` card
  in `dashboard_widgets.dart`. Tips are generated from real WaterProvider,
  MoodProvider, RoutinesProvider, and TodoProvider data — prioritised by most
  actionable need (hydration < 50% → mood missing → routines < 50% → pending
  tasks → all-good message). Honest labelling: no longer claims "AI".
- Wrapped all bare `debugPrint` calls in `CumulativeStatsService` with
  `if (kDebugMode)` guards so production APK stays clean.
- Deleted `assets/krumzi-video.mp4` — untracked, unreferenced by code or pubspec.
- Added `test/features/water/water_intake_test.dart` with 11 unit tests covering
  `WaterIntake.getProgress`, `isGoalReached`, `copyWith`, and the delete-log
  total-recalculation logic. All 12 tests pass (11 new + 1 smoke).
- `flutter analyze`: no issues. `dart format`: clean.

## 2026-05-30 (Test Coverage Expansion)

- Added `test/features/todo/daily_todo_test.dart` (17 tests): markAsCompleted,
  markAsIncomplete, copyWith, priorityText (Low/Medium/High/fallback), date
  helpers (isToday/isPast/isFuture), and equality by id.
- Added `test/features/routines/routine_test.dart` (18 tests): RoutineItem
  isCheckedToday edge cases, Routine allItemsCheckedToday, computeNextStreak
  (first completion, consecutive, today guard, gap reset), isActiveOnDay (null
  /empty=all-days, specific days), and copyWith with clearLastStreakDate and
  clearTime flags.
- Total test count: 46 (all passing).

## 2026-05-30 (Pre-Release UI & Flow Polish)

- **Onboarding Name Validation:** Added validation in `OnboardingPage` to prevent users from completing onboarding with an empty name field. A Snackbar prompts the user to enter their name, and auto-scrolls to the name page if skipped.
- **Dynamic Achievements Carousel:** Removed hardcoded mock data from `AchievementsCarousel` in `ProfilePage`. It now dynamically loads unlocked badges from `ChallengesProvider`. Added a working "See All" button that navigates to the `ChallengesPage`.
- **Challenges Settings Button:** Fixed the broken settings icon in `ChallengesPage` hero header to properly navigate to `SettingsPage` instead of a no-op `onPressed`.
