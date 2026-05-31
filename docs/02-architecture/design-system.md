# Design System

The current UI direction is warm, personal, and depth-based.

## Core Files

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/theme_extensions.dart`
- `lib/core/providers/theme_provider.dart`
- `lib/core/widgets/elevated_card.dart`
- `lib/core/widgets/glass_container.dart`
- `lib/core/widgets/glass_nav_bar.dart`
- `lib/core/widgets/page_header.dart`

## Current Style

- Warm primary color.
- Light and dark themes.
- Glass navigation.
- Elevated/neumorphic cards.
- Lucide icons for many actions.
- Dashboard sections organized by product area.

## Guidelines

- Prefer existing core widgets before creating new card/button styles.
- Keep spacing and navbar clearance consistent with `LayoutConstants`.
- Check light and dark mode.
- Avoid one-off colors when theme/provider colors are available.
