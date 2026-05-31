# Active Tasks

Use this file for work in progress. For larger tasks, create a separate note
using `_templates/task.md` and link it here.

## Current

_No active tasks. P0 release tasks, Kora Redesign, and post-redesign fixes are complete._

## Known remaining visual polish (not blocking)

- Affirmations `WelcomeStep` / `RecordStep` / `SessionStep` top bars: currently rely on the parent for header — consider adding per-step top bars matching the design spec (Sleep Affirmations header, Record + 2/3 indicator, Session).
- Breathing `BreathingSessionPage` (active session screen): not yet audited against redesign.
- Mood: `_TodayMoodCard` uses `Icon(level.icon)` — already replaced with `_MoodFaceWidget` in the entry card but verify the today card shows SVG face correctly.

## Task Format

```md
### Task Name

- Goal:
- Files:
- Notes:
- Test plan:
- Status:
```
