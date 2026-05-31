# ADR-0001: Provider And Local-First Storage

## Status

Accepted as current architecture.

## Context

Kora is a personal tracking app where most data can live locally. The existing
codebase already uses Provider, Hive, SharedPreferences, and feature modules.

## Decision

Continue with:

- Provider for app and feature state.
- Hive for structured local records.
- SharedPreferences for simple settings/counters/cache.
- FlutterSecureStorage for sensitive profile/user values.
- Feature-based folders under `lib/features/`.

## Consequences

- Offline-first behavior stays simple.
- Feature work should follow existing provider/repository/data-source patterns.
- Hive type IDs and migrations need stricter documentation.
- Tests should focus on providers, repositories, and date/storage behavior.
