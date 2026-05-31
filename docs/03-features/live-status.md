# Feature Live Status

Last audited: 2026-05-31.

## Summary

| Feature | Status | Live Notes |
| --- | --- | --- |
| Onboarding | Working | Stores local name/focus. Empty name validation prevents skipping. Brand is Kora. UI redesigned (2026-05-31). |
| Home | Working | Dashboard loads local providers. "Daily Tip" card shows dynamic tips based on real water/mood/routine/todo data. UI redesigned (2026-05-31). |
| Todo | Working | Local Hive CRUD. Extensively tested (17 unit tests). Stats behavior around deletes should be reviewed. UI redesigned (2026-05-31). |
| Routines | Working | Local Hive CRUD and streak logic extensively tested (18 unit tests). Notification behavior verified on device. UI redesigned (2026-05-31). |
| Water | Working | Local tracking works. All-time stats calculation and goal tracking extensively tested (11 unit tests). Stats integrity fixed. UI redesigned (2026-05-31). |
| Mood | Working | Local daily mood works. UI redesigned (2026-05-31). Data-source recovery can delete old box on open failure. |
| Gratitude | Working | Local entries/streaks. UI redesigned (2026-05-31). |
| Breathing | Partially working | Session/audio/haptic flow exists. UI redesigned (2026-05-31). Custom technique paths look incomplete/not surfaced. |
| Affirmations | Working | Recording/playback flow exists. UI redesigned (2026-05-31). typeId conflict resolved (moved to 12). |
| Challenges | Working | Local gamification exists. Release icon tree-shaking issue is fixed. Settings icon navigates correctly. |
| Calendar | Working | Events and reminders exist. Background notifications verified on device. UI redesigned (2026-05-31). |
| Timer | Working | Timer page works locally. UI redesigned (2026-05-31). Voice "start timer" now triggers TimerProvider. |
| Settings | Mostly working | Debug/test notification controls were removed from the user-facing screen. |
| Profile | Working | Local-only profile. Achievements carousel dynamically loads unlocked badges. Needs naming/support-copy pass. |
| Voice/NLP | Partially working | Some commands execute. Debug prints, no confirmation, unsupported commands remain. |
| Analytics | Not wired | `AnalysisCard` exists but Home uses a static insight card. |
| Home Widget | Disabled for v1 | Dependency was removed and runtime service is a no-op until Android tooling/dependency strategy is revisited. |

## Recommended v1 Scope

Ship local-only:

- Onboarding
- Home
- Todo
- Routines
- Water
- Mood
- Gratitude
- Breathing
- Affirmations
- Calendar (Notifications verified)
- Challenges
- Profile

Hold or hide until implemented:

- Premium badge/status
- Export data
- Voice timer command
- Static "AI Insight" copy or label it as a tip (Done - changed to Daily Tip)

## Feature-Specific Fix Notes

### Profile

There is no auth implementation under `lib/features/auth/`; the folders are
empty. Profile is now local-only and no longer shows fake account, Premium,
Export Data, or Sign Out affordances.

### Release Build

Dynamic `IconData` reconstruction was replaced with stable icon lookup mappings
for breathing and challenges so release icon tree shaking can stay enabled.

### Storage

The concrete `typeId: 10` conflict is fixed. The remaining decision is whether
the unused/data-layer affirmation Hive repository should stay in v1.

### Permissions

Android release has `INTERNET` for network-backed daily quotes.
iOS likely needs speech recognition usage text if voice commands are shipped on
iOS.
