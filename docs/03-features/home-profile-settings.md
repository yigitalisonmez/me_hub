# Feature: Home, Profile, Settings

## Purpose

Home is the main dashboard. Profile and settings manage user-facing preferences
and summary UI.

## Code Roots

- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/profile/presentation/`
- `lib/features/settings/presentation/`
- `lib/core/providers/theme_provider.dart`

## Notes

- Home loads data from Todo, Water, Mood, and Routines providers.
- Home shows a dynamic Daily Tip from local provider data, not an AI-labelled
  static insight.
- Home dashboard "Soon" tiles are visually disabled and non-interactive.
- Profile currently reads user name through secure storage.
- Profile is local-only and avoids fake account, Premium, Export Data, Sign Out,
  and support/contact promises that do not exist yet.
- Profile shows the persisted water goal and opens Water Settings to edit it.
- Profile's three cumulative summary metrics use rolling digit transitions;
  continuously updating values remain plain text.
- Settings has a full-page shell with separate Appearance and Voice sections.
- Dark mode is managed only from Settings.
- Keep dashboard navigation consistent with `MainScreen` and `GlassNavBar`.

## Live Audit Notes

- Profile is local-only and avoids fake account, Premium, Export Data, and Sign
  Out affordances.
- Home and Mood avoid user-facing "AI" labels unless the feature is actually
  backed by an AI flow.
- Settings debug notification tools were removed from the user-facing screen.
- Profile does not show reminder/privacy controls or analytics percentages until
  those features are backed by real behavior and data.
- Water Goal now exposes persisted reminder controls backed by the shared
  reminder provider.
- Home, Profile, and Onboarding pages fully redesigned as part of Kora Redesign
  (2026-05-31).
