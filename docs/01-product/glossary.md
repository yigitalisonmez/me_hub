# Glossary

## Kora

The app name and overall personal hub experience.

## me_hub

The internal Flutter/Dart package and repository name. This may remain different
from the user-facing app name.

## Feature

A product area under `lib/features/<feature>/`, such as `todo`, `routines`, or
`water`.

## Provider

A `ChangeNotifier` used for UI state and feature actions.

## Data Source

The layer that talks to Hive, SharedPreferences, APIs, or platform services.

## Repository

The abstraction between domain/usecases and data sources.

## Use Case

A small domain action class, usually in `domain/usecases/`.

## Hive Type ID

A numeric ID used by Hive adapters. These must be unique across all registered
adapters.
