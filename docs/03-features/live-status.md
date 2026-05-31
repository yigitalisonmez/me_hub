# Feature Live Status

Last audited: 2026-05-30.

## Summary

| Feature | Status | Live Notes |
| --- | --- | --- |
| Onboarding | Working | Stores local name/focus. Empty name validation prevents skipping. Brand is Kora. |
| Home | Working | Dashboard loads local providers. "Daily Tip" card shows dynamic tips based on real water/mood/routine/todo data. |
| Todo | Working | Local Hive CRUD. Extensively tested (17 unit tests). Stats behavior around deletes should be reviewed. |
| Routines | Working | Local Hive CRUD and streak logic extensively tested (18 unit tests). Notification behavior verified on device. |
| Water | Working | Local tracking works. All-time stats calculation and goal tracking extensively tested (11 unit tests). |
| Mood | Mostly working | Local daily mood works. Data-source recovery can delete old box on open failure. |
| Gratitude | Mostly working | Local entries/streaks. Needs tests and UI walkthrough. |
| Breathing | Partially working | Session/audio/haptic flow exists. Custom technique paths look incomplete/not surfaced. |
| Affirmations | Partially working | Recording/playback flow exists. Dead Hive repository/model remains, but concrete typeId conflict is fixed. |
| Challenges | Working | Local gamification exists. Release icon tree-shaking issue is fixed. Settings icon navigates correctly. |
| Calendar | Working | Events and reminders exist. Background notifications verified successfully on physical device. |
| Timer | Local only | Timer page works locally. Voice "start timer" does not start TimerProvider. |
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
