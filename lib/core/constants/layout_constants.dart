import 'package:flutter/material.dart';

/// Layout constants for consistent spacing throughout the app
class LayoutConstants {
  LayoutConstants._();

  /// Height of the floating glass navbar
  static const double navbarHeight = 70;

  /// Bottom margin of the navbar from screen edge
  static const double navbarBottomMargin = 12;

  /// Horizontal margin of the navbar
  static const double navbarHorizontalMargin = 16;

  /// Extra padding above navbar for comfortable scrolling
  static const double navbarContentBuffer = 16;

  /// Calculate the total clearance needed for content to scroll past navbar
  /// This accounts for navbar height, margins, safe area, and buffer
  static double getNavbarClearance(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    return navbarHeight +
        navbarBottomMargin +
        bottomSafeArea +
        navbarContentBuffer;
  }

  /// Get bottom padding for scrollable content that needs to clear the navbar
  static EdgeInsets getNavbarPadding(BuildContext context) {
    return EdgeInsets.only(bottom: getNavbarClearance(context));
  }
}
