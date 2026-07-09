# Done

## 2026-07-09 (Kora Redesign — Insights section + polish)

- Implemented the last unbuilt parts of the Kora Redesign board (section 6,
  Insights & quick log) plus remaining visual polish:
  - New `lib/features/insights/` module: pure `ConsistencyCalculator`,
    read-only `InsightsDataService` aggregating todos/water/mood/gratitude/
    session histories.
  - `ConsistencyPage`: streak hero, 16-week heatmap with tappable day detail,
    legend, and stats. Entries: Explore → Insights and the Profile day-streak
    card.
  - `WeeklyWrappedPage`: five-slide auto-advancing story (hydration bars,
    productivity, mood trend, streak) with tap/swipe navigation and
    `share_plus` text sharing. Entries: Sunday-only Home banner and Explore.
  - Quick-log bottom sheet (water stepper, five-bucket mood picker, first
    three tasks) opened from a floating "Quick log" pill on the Home tab.
  - Added the 3/3 marker to the affirmation Session top bar; audited
    `BreathingSessionPage` and aligned breathing technique colors to the Kora
    palette (mindful/water/routine/terracotta deeps).
- Also committed pre-existing working-tree work as-is (timer notification
  gateway + wall-clock timer provider, onboarding rework, store-listing docs).
- **Validation**:
  - `dart format`: applied to all touched files.
  - `flutter analyze`: no issues.
  - `flutter test`: all 121 tests passed (7 new calculator tests).

## 2026-06-07 (Animated Water Metric)

- Added the `animated_digit` package and a reusable, reduced-motion-aware
  `AnimatedMetricText` core widget.
- Replaced the Water page's main consumed-liter text with a rolling value that
  animates on first display and after add, undo, or delete updates.
- Extended rolling metrics to the fixed Profile and Challenges summary cards.
  Timers and repeating list rows stay static because the package creates a
  scroll controller and digit list for every animated digit.
- Added widget tests for precision, value updates, semantics, and reduced
  motion behavior, including six simultaneous low-frequency metrics.
- **Validation**:
  - `flutter analyze`: no issues.
  - `flutter test`: all 87 tests passed.
  - Android profile APK built and launched successfully on a physical 120 Hz
    device.
  - Eight spaced Water quick-add updates produced 417 measured animation
    frames. UI frame work was 1.49 ms median / 3.27 ms max; raster work was
    3.34 ms median / 6.20 ms max. No UI or raster frame exceeded the 8.33 ms
    120 Hz budget.
  - The embedder reported six isolated one-vsync presentation misses during
    ADB-driven interaction. Since UI and raster work stayed within budget,
    these did not indicate an `animated_digit` computation or painting
    bottleneck.

Completed work should be summarized here with date, changed files, and test
results.

## 2026-06-08 (Persisted Feature Reminders)

- Added a versioned reminder preferences repository, stable notification ID
  registry, pure schedule planner, platform gateway, and scoped coordinator.
- Added global and per-feature Settings controls plus Water Goal, Routine, and
  Calendar-owned controls.
- Added completion-aware reminders for Water, Mood, Gratitude, Breathing,
  Affirmations, Todo, Challenges, and weekly insights.
- Added permission-aware blocked state, contextual permission requests, system
  settings navigation, typed notification payload navigation, and legacy
  migration cleanup.
- Removed unused Android notification/service permissions and retained inexact
  fallback for Calendar.
- Added reminder serialization, migration, scheduling, collision, namespace,
  permission, and master-toggle tests.
- **Validation**:
  - `flutter analyze`: no issues.
  - `flutter test`: all 104 tests passed.
  - Profile APK built, installed, and launched on a physical SM-S908E.
  - Kora remained the focused foreground activity with no startup notification
    permission dialog or ANR.

## 2026-06-07 (Profile and Settings Accuracy Cleanup)

- Removed the fabricated Profile insight percentage and its nonfunctional full
  report affordance.
- Removed Profile controls for dark mode, reminders, and privacy because those
  locations did not provide matching implemented behavior.
- Profile now shows the persisted water goal, opens Water Settings, and refreshes
  both its label and `WaterProvider` after a successful save.
- Static Profile rows no longer show a chevron unless they are interactive.
- Settings now uses separate Appearance and Voice sections; dark mode remains
  the single theme control and `en_US` uses the United States flag.
- Removed the decorative, nonfunctional reminder controls from Water Goal.
- Recorded the deferred reminder, privacy/data-management, analytics-report, and
  quick-theme ideas in `01-product/future-ideas.md`.
- Added widget coverage for Profile cleanup, water-goal synchronization,
  Settings persistence, locale presentation, and removal of fake reminder UI.
- **Validation**:
  - `dart format`: completed for touched Dart files.
  - `flutter analyze`: no issues.
  - `flutter test`: all 81 tests passed.

## 2026-06-06 (Water + Mood Interaction Polish)

- **Water feedback**: Quick-add actions now animate the jug with a 500 ms pulse,
  smoothly raise the displayed level, and show a themed floating confirmation
  message above the bottom navigation.
- **Water surface**: Rebuilt the jug fill with two connected, counter-moving
  wave layers so the surface remains filled edge to edge without the old seam.
- **Goal celebration**: Reaching the daily target now adds a water-colored glow
  and an animated in-jug "Goal reached!" message for 2.6 seconds.
- **Mood motion**: The mood orb keeps a stable layout size while emitting a
  calm 4.5-second pulse ring. Selecting a mood now morphs the orb color, pops in
  the new face, and slides/fades the label and caption.
- **Mood controls**: Mood scale buttons and factor chips now have compact press
  feedback without shifting the surrounding layout.
- **Routine duration follow-up**: Guided routine timers now use the persisted
  per-step duration, with a model test covering `RoutineItem.copyWith`.
- **Changed files**:
  - `lib/features/water/presentation/pages/water_page.dart`
  - `lib/features/water/presentation/widgets/todays_progress_card.dart`
  - `lib/features/water/presentation/widgets/quick_add_section.dart`
  - `lib/features/mood_tracker/presentation/pages/mood_page.dart`
  - `lib/features/routines/presentation/pages/guided_routine_flow_page.dart`
  - `test/features/routines/routine_test.dart`
- **Validation**:
  - `dart format`: completed for touched Dart files.
  - `flutter analyze`: no issues.
  - `flutter test`: all 77 tests passed.

## 2026-06-03 (Routine Icon Picker Theme)

- **Select icon dialog**: Redesigned the routine step icon picker to match the
  Kora app theme with warm surfaces, softer borders/shadows, compact search,
  rounded icon tiles, and routine-accent selected states.
- **Routine color support**: New routine step icon picking now uses the current
  selected routine color; edit routine uses the routine green accent.
- **Changed files**:
  - `lib/features/routines/presentation/widgets/icon_picker_dialog.dart`
  - `lib/features/routines/presentation/pages/create_routine_page.dart`
  - `lib/features/routines/presentation/pages/edit_routine_page.dart`
- **Validation**:
  - `dart format`: completed for touched files.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-06-03 (Routine Step Icons)

- **Step icon selection**: New routine and edit routine screens now let each
  step choose its own icon through the existing routine icon picker.
- **Persisted item icons**: Created and edited routine steps save their selected
  `RoutineItem.iconCodePoint`, while existing step ids/check state are preserved
  on edit.
- **Routine detail display**: Guided routine detail/start rows and next-step
  hints now render the step icon with a safe fallback.
- **Changed files**:
  - `lib/features/routines/presentation/pages/create_routine_page.dart`
  - `lib/features/routines/presentation/pages/edit_routine_page.dart`
  - `lib/features/routines/presentation/pages/guided_routine_flow_page.dart`
- **Validation**:
  - `dart format`: completed for touched files.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-06-03 (Routine Edit Redesign)

- **Edit routine screen**: Replaced the old edit form/bottom-sheet habit UI with
  the new routine design language: top action bar, live preview card, compact
  name/icon/time/repeat controls, inline step editor, and sticky Save changes
  CTA.
- **Step editing**: Routine steps can now be edited inline and reordered with
  drag handles; saved items preserve existing ids, icons, and checked dates.
- **Delete action**: Kept routine deletion available from the redesigned top bar.
- **Changed files**:
  - `lib/features/routines/presentation/pages/edit_routine_page.dart`
- **Validation**:
  - `dart format lib/features/routines/presentation/pages/edit_routine_page.dart`
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-06-03 (Guided Routine Flow)

- **Design handoff**: Fetched and read the Claude Design bundle, README, both
  chat transcripts, `Kora Redesign.html`, `routine-flow.jsx`, and the related
  `rfl-*` CSS sections.
- **Routine detail/start screen**: Added a guided routine detail page with a
  gradient hero, routine icon, schedule, step/minute/streak stats, animated step
  rows, and a full-width Start routine CTA.
- **Guided run player**: Added a step-by-step routine runner with progress
  segments, timer ring/orb, pause, skip, "Mark done & next", and exit
  confirmation.
- **Selectable step text**: Active step titles and guidance copy use
  `SelectableText`, so the user can select/copy the current step text without
  disrupting the flow.
- **Completion state**: Added a routine-complete screen with check mark,
  completed-step stats, elapsed time, streak, and Back to routines.
- **Routine list entry point**: Active routine cards now open the guided flow
  from the main card body or play action; edit/delete and expand checklist
  controls remain available.
- **Changed files**:
  - `lib/features/routines/presentation/pages/guided_routine_flow_page.dart`
  - `lib/features/routines/presentation/pages/routines_page.dart`
- **Validation**:
  - `dart format`: completed for touched files.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-06-01 (P0 Bug Fixes — Timezone, Mood Data Loss, Stale Docs)

- **P0-3 (docs)**: Rewrote `docs/02-architecture/release-readiness.md`.
  Replaced the stale "build fails / not live-ready" content with the accurate
  post-signing state. Moved all five resolved P0 blockers to a "Resolved
  Blockers" section. Added a "Remaining Work" section with genuinely open items.
  Updated `docs/02-architecture/notifications.md` to remove the hardcoded
  timezone live-audit note.
- **P0-2 (timezone)**: Added `flutter_timezone: ^3.0.1` to `pubspec.yaml`.
  Replaced the hardcoded `tz.getLocation('Europe/Istanbul')` in
  `NotificationService.initialize()` with a runtime device-timezone lookup via
  `FlutterTimezone.getLocalTimezone()`. Falls back to `tz.UTC` if the platform
  channel is unavailable. Removed stale Turkish-language comments referencing
  the previously removed `flutter_native_timezone` package.
- **P0-1 (mood data loss)**: Rewrote `MoodLocalDataSource.init()`.
  - Changed bare `catch (e)` to `on HiveError catch (e)` so that
    `FileSystemException`, permission errors, and other non-schema failures
    propagate to the caller instead of silently deleting data.
  - Added `_backupBoxFiles()`: copies `mood_entries.hive` to a timestamped
    backup before any delete, using `path_provider`. Best-effort — failure does
    not block recovery.
  - Added `_pruneOldBackups()`: keeps the 3 most recent backups, deletes older
    ones.
  - Adds a `mood_data_recovered` flag to SharedPreferences after recovery so
    `MoodProvider` can surface a one-time warning to the user.
  - Exposed `checkAndClearRecoveryFlag()` static method for `MoodProvider` to
    consume.
- **Changed files**:
  - `docs/02-architecture/release-readiness.md`
  - `docs/02-architecture/notifications.md`
  - `pubspec.yaml`
  - `lib/core/services/notification_service.dart`
  - `lib/features/mood_tracker/data/datasources/mood_local_datasource.dart`
- **Validation**:
  - `flutter pub get`: resolved `flutter_timezone 3.0.1`.
  - `flutter analyze`: no issues.
  - `flutter test`: 46/46 passed.

## 2026-06-01 (Goals & Challenges Redesign)

- **Design handoff**: Fetched and read the Claude Design bundle, README,
  transcript, `Kora Redesign.html`, and the `features3.jsx`/CSS sections for
  Goals and Challenges.
- **Goals screen**: Rebuilt the existing Goals/Challenges route with a Goals
  tab matching the design: analytics asset hero, Active/Done segmented control,
  progress cards with category tints, mini progress rings, bars, and metadata.
- **Goal creation**: Added a plus action that opens a weekly-goal template sheet
  and persists selected goals through the existing `ChallengesProvider`.
- **Challenges screen**: Added a separate Challenges tab with the amber active
  challenge spotlight, 30-day dot grid, check-in button, stat cards, and
  design-style join list.
- **Badges**: Kept the trophy action and moved all-badges viewing into the new
  design sheet.
- **Changed files**:
  - `lib/features/challenges/presentation/pages/challenges_page.dart`
- **Validation**:
  - `dart format`: completed for touched file.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-05-31 (Mood Today's Note + Save Button Fix)

- **Mood note input**: Rebuilt `Today's note` as a fixed-height, centered
  writing surface with the quote mark layered inside the card instead of taking
  its own row above the `TextField`.
- **Mood save button**: Removed the circular `Scaffold` FAB and replaced it with
  the design-matching 56px rounded-square plus button anchored beside the note
  section.
- **Changed files**:
  - `lib/features/mood_tracker/presentation/pages/mood_page.dart`
- **Validation**:
  - `dart format`: completed for touched file.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-05-31 (New Routine Flow + Final Redesign Bugfixes)

- **New routine flow**: Replaced the old 3-step create routine wizard with the
  design-spec single-screen flow:
  - live preview card
  - routine name field
  - icon grid
  - color swatches
  - time picker
  - repeat day selector
  - editable routine steps
  - reminder switch
  - full-width Create routine CTA
- **Routine persistence**: `RoutinesProvider.addNewRoutine` now accepts optional
  `items` and `scheduleNotifications`, so created flow steps are saved as real
  `RoutineItem`s and reminders can be disabled without dropping the routine time.
- **Affirmations session animation**: `affirmation.png` now floats upward and
  subtly scales while the session is playing.
- **Affirmations dark mode**: Record selected tile background now uses a dark
  blended mindful surface so text stays readable.
- **Water jug fill**: Hydro painter fill now bleeds past the circle edges and
  adds a lower fill rect, fixing the unfilled gap on the right side.
- **Home daily summary navigation**: Tasks, Water, Mood, and Routines summary
  cards now navigate to their matching feature pages.
- **Changed files**:
  - `lib/features/routines/presentation/pages/create_routine_page.dart`
  - `lib/features/routines/presentation/providers/routines_provider.dart`
  - `lib/features/affirmations/presentation/widgets/session_step.dart`
  - `lib/features/affirmations/presentation/widgets/record_step.dart`
  - `lib/features/water/presentation/widgets/todays_progress_card.dart`
  - `lib/features/todo/presentation/widgets/dashboard_widgets.dart`
  - `lib/features/home/presentation/pages/home_page.dart`
- **Validation**:
  - `dart format`: completed for touched files.
  - `flutter analyze`: no issues.
  - `flutter test`: all tests passed.

## 2026-05-31 (Mood Design Match + Affirmations Glow/Button)

- **Mood FAB**: `FloatingActionButton` (moodDeep, +) added to Scaffold. Visible when no today mood; tapping saves the current entry.
- **Mood divider**: thin `Divider` between scale and factors section (matches design `m3-divider`).
- **Mood label**: "What is shaping it" → "What's shaping it".
- **Mood note**: Redesigned as blockquote — amber large `"` prefix + italic `TextField` inside a Container (no more filled OutlineInputBorder).
- **WelcomeStep glow**: `ImageFilter.blur` sigma 22→38, circle 200px, alpha 0.55 — glow now spreads wide.
- **WelcomeStep button**: Removed `MediaQuery.padding.bottom` from CTA padding (SafeArea already handles nav bar) — button now sits just above Android nav area.

## 2026-05-31 (Affirmations Flow — Black Screen + Glow + RecordStep Redesign)

- **Black screen fix**: `_SleepAffirmationsFlowPage` Scaffold was `Colors.transparent` → RecordStep/SessionStep had no background. Restored to `themeProvider.backgroundColor`.
- **WelcomeStep glow**: Replaced `RadialGradient` Container with `ImageFiltered(blur σ=22)` — glow now spreads beyond its bounds like CSS `filter:blur(6px)`.
- **RecordStep redesign** (design spec match):
  - Own `Container` background + `SafeArea`
  - Top bar: ← back | "Record" | "2/3" step indicator
  - Timer as `RichText`: "0:18  / 1:00" large+small format
  - Record button: white circle + border + red rounded square (idle); switches to pause/play icon
  - "Done" pill shown during active recording
  - Recordings list: play circle + name/duration + delete + radio-select per row
  - "Record another · N left" dashed tinted button
  - Full-width "Use selected for session →" bottom button
- **SessionStep**: Added `mindfulTint→bg` gradient background, top bar with ← (shown when idle) + "Session" title.
- `flutter analyze`: no issues.

## 2026-05-31 (Page Transitions)

New `lib/core/utils/app_route.dart`:
- `AppRoute` — fade + 4.5% slide-up, 300ms easeOutCubic push / 240ms pop. Used for all feature navigations.
- `AppFadeRoute` — pure fade 380ms for one-way replacements (onboarding → main screen).

All 19 `MaterialPageRoute` usages replaced across: home (9 feature pages), affirmations, breathing, routines (2), water, challenges, gratitude, profile (2), onboarding.

`flutter analyze`: passes cleanly.

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
