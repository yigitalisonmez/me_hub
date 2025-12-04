# Task: Refactor UI for Depth and Layering

## Status: Completed

## Objectives
- [x] Refactor `RoutinesPage` and `RoutineItemWidget`.
- [x] Refactor `DailyQuoteWidget`.
- [x] Refactor `TodoCardWidget`.
- [x] Refactor `MoodPage`.
- [x] Refactor `WaterPage` widgets (`TodaysProgressCard`, `TodaysLogSection`, `WaterLogItem`, `WaterAmountButton`, `WaterStatCard`).
- [x] Refactor `SettingsPage`.
- [x] Refactor `PageHeader` and `EmptyStateWidget`.
- [x] Create reusable `ElevatedCard` widget.
- [x] Refactor all cards to use `ElevatedCard`.
- [x] Verify build and fix errors.
  - [x] Fixed `DailyQuoteWidget` import error.
  - [x] Fixed `MoodPage` undefined `isDark` error.
  - [x] Fixed `SettingsPage` undefined `isDark` error.
  - [x] Fixed unused imports and print statements.

## Notes
- Created `ElevatedCard` in `lib/core/widgets/elevated_card.dart` to centralize the bevel effect logic.
- Applied "Bevel" effect (light top shadow, dark bottom shadow) for realistic elevation.
- Applied "Inset" effect for recessed elements (e.g., unselected days, icon containers).
- Used monochromatic layering with base colors and opacity adjustments.
- Ensured consistent design language across the app.
- Cleaned up code by removing unused imports and replacing `print` with `debugPrint`.
