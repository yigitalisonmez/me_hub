# State Management

The app primarily uses Provider.

## Provider Types

- `Provider<T>` for repositories and stable services.
- `ChangeNotifierProvider<T>` for UI state and feature actions.
- `Consumer<T>` or `context.watch<T>()` for reactive UI.
- `context.read<T>()` for actions and one-time reads.

## Common Flow

```text
Widget -> Provider -> UseCase -> Repository -> DataSource -> Local storage
```

Some newer or smaller features shortcut this pattern. Prefer matching the
feature you are editing rather than forcing a full rewrite.

## Guidelines

- Keep provider state explicit: loading, error, data.
- Avoid long business logic inside widgets.
- Avoid direct storage access from UI widgets unless that is already the local
  pattern for the feature.
- Be careful with `BuildContext` after `await`; use mounted checks that guard the
  same context.
