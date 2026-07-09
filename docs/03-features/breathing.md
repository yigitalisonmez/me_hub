# Feature: Breathing

## Purpose

Guided breathing sessions with techniques, animation, mood checks, background
audio, session history, and custom techniques.

## Code Roots

- `lib/features/breathing/domain/`
- `lib/features/breathing/data/`
- `lib/features/breathing/presentation/`

## Storage

- SharedPreferences-backed repository for sessions/settings/custom techniques.
- Audio playback uses `just_audio`.

## Notes

- Provider is large. Prefer small, focused edits.
- Always check timer/audio disposal when changing session lifecycle.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
- Technique preset colors use the Kora palette (mindful/water/routine/
  terracotta deeps) since 2026-07-09; preset lists are duplicated in both
  `data/models` and `domain/entities` versions of `breathing_technique.dart` —
  keep them in sync.
