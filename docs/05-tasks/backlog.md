# Backlog

## Architecture

- [ ] Add storage inventory with every box/key and owning feature.
- [ ] Split large providers if they become risky to maintain.
- [ ] Align Android namespace/applicationId and iOS bundle ID.

## Quality

- [ ] Clean `avoid_print` warnings in voice/NLP code.
- [x] Add tests for TodoProvider. (`test/features/todo/daily_todo_test.dart` — 17 tests)
- [x] Add tests for routine streak logic. (`test/features/routines/routine_test.dart` — 18 tests)
- [x] Add tests for WaterProvider all-time stats behavior after undo/delete. (`test/features/water/water_intake_test.dart` — 11 tests)
- [ ] Add tests for calendar reminder time calculation.
- [ ] Add tests for MoodLocalDataSource date-key behavior.
- [ ] Add smoke widget test that actually pumps the app with mock/local dependencies.

## Product

- [ ] Improve calendar reminder UX.
- [ ] Expand analytics cards.
- [ ] Improve voice command confirmation flow.
- [x] Wire real AnalysisCard into Home. (ADR-002 Phase 3 — done 2026-06-02)
- [ ] Implement voice timer command or remove it from supported NLP actions.

## Deferred / Later

These were intentionally removed or disabled during the live-readiness pass so
v1 does not imply features that are not implemented yet.

- [ ] Re-add Home Widget support after choosing a compatible strategy:
  upgrade Android tooling, downgrade/replace `home_widget`, or build native
  widget support without the current dependency path.
- [ ] Add real auth if the product should have accounts. Until then Profile is
  local-only and should not show sign-in/sign-out.
- [ ] Add data export/import as a real feature before showing Export Data again.
- [ ] Add Premium/entitlement only after there is a real billing or entitlement
  source.
- [ ] Add a local reset/onboarding reset action if local-only v1 needs an
  account-like escape hatch.
- [ ] Decide whether the old affirmation Hive repository should be kept,
  migrated, or removed now that the concrete typeId conflict is fixed.
