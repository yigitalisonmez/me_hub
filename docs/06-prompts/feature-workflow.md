# Prompt: Feature Workflow

Use this when starting a feature task with Claude/Codex.

```text
Read CLAUDE.md, docs/00-start-here.md, docs/02-architecture/overview.md, and
docs/03-features/<feature>.md.

Task:
<describe the feature/change>

Constraints:
- Follow existing Provider/Hive patterns.
- Do not edit generated *.g.dart files manually.
- Check git status before edits.
- Update relevant docs after the change.

Verification:
- dart format lib test
- flutter analyze
- flutter test or targeted tests
```
