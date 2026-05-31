# Architecture Overview

## Shape

Kora is a Flutter app organized around feature modules.

```text
lib/
  main.dart
  core/
    constants/
    errors/
    providers/
    services/
    theme/
    utils/
    widgets/
  features/
    <feature>/
      data/
      domain/
      presentation/
```

Not every feature currently has all three layers, but mature features generally
do.

## Main Patterns

- `ChangeNotifierProvider` and `Provider` are wired in `main.dart`.
- Feature providers expose UI state and user actions.
- Repositories wrap data sources for most local-first features.
- Hive stores structured entities/models.
- SharedPreferences stores smaller settings, counters, and history.
- Core widgets/theme provide the shared visual language.

## Before Changing Code

1. Check `git status --short`.
2. Read the relevant feature note in `03-features/`.
3. Check whether the change touches Hive, notifications, voice/NLP, or app
   startup.
4. Prefer existing patterns over new abstractions.

## After Changing Code

1. Run `dart format lib test`.
2. Run `flutter analyze`.
3. Run targeted tests or `flutter test`.
4. Update docs if behavior, architecture, storage, or commands changed.
