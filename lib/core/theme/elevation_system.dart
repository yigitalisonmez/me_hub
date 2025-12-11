import 'package:flutter/material.dart';

/// Elevation levels for consistent depth hierarchy
enum ElevationLevel {
  background, // Level 0 - Base
  surface, // Level 1 - Cards, panels
  raised, // Level 2 - Interactive elements
  elevated, // Level 3 - Modals, dialogs
  overlay, // Level 4 - Dropdowns, tooltips
}

/// Monochromatic elevation system using layered shades
/// Creates realistic depth using dual shadows (bevel effect)
class ElevationSystem {
  ElevationSystem._();

  // === DARK MODE MONOCHROMATIC PALETTE ===
  // Base: #2C2C2C
  static const Color _darkBase = Color(0xFF2C2C2C);
  static const Color _darkSurface = Color(0xFF363636); // +5% lightness
  static const Color _darkRaised = Color(0xFF424242); // +10% lightness
  static const Color _darkElevated = Color(0xFF4D4D4D); // +15% lightness
  static const Color _darkOverlay = Color(0xFF575757); // +20% lightness

  // Shadow colors for dark mode
  static const Color _darkShadowLight = Color(0xFF4A4A4A); // Top highlight
  static const Color _darkShadowDark = Color(0xFF1A1A1A); // Bottom shadow

  // === LIGHT MODE MONOCHROMATIC PALETTE ===
  // Base: #F0EBE5 (warm beige)
  static const Color _lightBase = Color(0xFFF0EBE5);
  static const Color _lightSurface = Color(0xFFF5F2ED); // +3% lightness
  static const Color _lightRaised = Color(0xFFFAF8F5); // +6% lightness
  static const Color _lightElevated = Color(0xFFFFFFFF); // White
  static const Color _lightOverlay = Color(0xFFFFFFFF);

  // Shadow colors for light mode
  static const Color _lightShadowLight = Color(0xFFFFFFFF); // Top highlight
  static const Color _lightShadowDark = Color(0xFFD4CFC8); // Bottom shadow

  /// Get fill color for elevation level
  static Color getColor(ElevationLevel level, {required bool isDark}) {
    if (isDark) {
      switch (level) {
        case ElevationLevel.background:
          return _darkBase;
        case ElevationLevel.surface:
          return _darkSurface;
        case ElevationLevel.raised:
          return _darkRaised;
        case ElevationLevel.elevated:
          return _darkElevated;
        case ElevationLevel.overlay:
          return _darkOverlay;
      }
    } else {
      switch (level) {
        case ElevationLevel.background:
          return _lightBase;
        case ElevationLevel.surface:
          return _lightSurface;
        case ElevationLevel.raised:
          return _lightRaised;
        case ElevationLevel.elevated:
          return _lightElevated;
        case ElevationLevel.overlay:
          return _lightOverlay;
      }
    }
  }

  /// Get bevel shadow (dual shadow for realistic depth)
  /// Top: light/highlight, Bottom: dark shadow
  static List<BoxShadow> getBevelShadow(
    ElevationLevel level, {
    required bool isDark,
  }) {
    final shadowLight = isDark ? _darkShadowLight : _lightShadowLight;
    final shadowDark = isDark ? _darkShadowDark : _lightShadowDark;

    switch (level) {
      case ElevationLevel.background:
        return [];

      case ElevationLevel.surface:
        return [
          // Top highlight
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.05 : 0.7),
            offset: const Offset(0, -1),
            blurRadius: 1,
          ),
          // Bottom shadow
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.3 : 0.15),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ];

      case ElevationLevel.raised:
        return [
          // Top highlight
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.08 : 0.8),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
          // Bottom shadow
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ];

      case ElevationLevel.elevated:
        return [
          // Top highlight
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.1 : 0.9),
            offset: const Offset(0, -2),
            blurRadius: 3,
          ),
          // Bottom shadow
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(0, 6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];

      case ElevationLevel.overlay:
        return [
          // Top highlight
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.12 : 1.0),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
          // Bottom shadow
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
    }
  }

  /// Get inset shadow for sunken/recessed elements (inputs, wells)
  static List<BoxShadow> getInsetShadow({required bool isDark}) {
    final shadowDark = isDark ? _darkShadowDark : _lightShadowDark;
    final shadowLight = isDark ? _darkShadowLight : _lightShadowLight;

    return [
      // Inner top shadow (creates recessed look)
      BoxShadow(
        color: shadowDark.withValues(alpha: isDark ? 0.3 : 0.12),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
      // Inner bottom highlight
      BoxShadow(
        color: shadowLight.withValues(alpha: isDark ? 0.02 : 0.5),
        offset: const Offset(0, -1),
        blurRadius: 1,
      ),
    ];
  }

  /// Get input field fill color - LIGHTER than surface (elevated, pops toward user)
  static Color getInputFillColor({required bool isDark}) {
    // Interactive elements should be LIGHTER (closer to user)
    return isDark
        ? const Color(0xFF4D4D4D) // Lighter than elevated - pops forward
        : const Color(0xFFFFFFFF); // Pure white - maximum brightness
  }

  /// Get selected/active element shadow with color glow
  static List<BoxShadow> getActiveShadow(
    Color accentColor, {
    required bool isDark,
  }) {
    return [
      // Colored glow
      BoxShadow(
        color: accentColor.withValues(alpha: isDark ? 0.4 : 0.3),
        offset: const Offset(0, 0),
        blurRadius: 12,
        spreadRadius: 0,
      ),
      // Top highlight
      BoxShadow(
        color: (isDark ? _darkShadowLight : _lightShadowLight).withValues(
          alpha: isDark ? 0.1 : 0.9,
        ),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
      // Bottom shadow
      BoxShadow(
        color: (isDark ? _darkShadowDark : _lightShadowDark).withValues(
          alpha: isDark ? 0.4 : 0.2,
        ),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }
}
