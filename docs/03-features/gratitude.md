# Feature: Gratitude

## Purpose

Daily gratitude entries, gratitude items, prompts, streaks, and reflections.

## Code Roots

- `lib/features/gratitude/domain/`
- `lib/features/gratitude/data/`
- `lib/features/gratitude/presentation/`

## Storage

- Hive box: verify in `gratitude_local_datasource.dart`
- Hive type IDs: 40, 41, 42

## Notes

- Some widgets still use deprecated `withOpacity`; this appears in analyzer
  output and can be cleaned when touching the feature.
