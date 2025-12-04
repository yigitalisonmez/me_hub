import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MoodUtils {
  static Color getColorForScore(int score) {
    if (score <= 4) {
      // 1-4: Muted Terra Cotta to Primary Orange
      final normalized = (score - 1) / 3.0;
      return Color.lerp(
        const Color(0xFFA95C68), // Muted Terra Cotta
        const Color(0xFFD97D45), // Primary Orange
        normalized,
      )!;
    } else if (score <= 7) {
      // 5-7: Primary Orange to Warm Yellow/Ochre
      final normalized = (score - 5) / 2.0;
      return Color.lerp(
        const Color(0xFFD97D45), // Primary Orange
        const Color(0xFFE1C16E), // Warm Yellow / Ochre
        normalized,
      )!;
    } else {
      // 8-10: Warm Yellow/Ochre to Sage Green
      final normalized = (score - 8) / 2.0;
      return Color.lerp(
        const Color(0xFFE1C16E), // Warm Yellow / Ochre
        const Color(0xFF8BA888), // Sage Green
        normalized,
      )!;
    }
  }

  static IconData getIconForScore(int score) {
    if (score <= 2) return LucideIcons.frown;
    if (score <= 4) return LucideIcons.meh;
    if (score <= 6) return LucideIcons.smile;
    if (score <= 8) return LucideIcons.laugh;
    return LucideIcons.partyPopper;
  }

  static String getLabelForScore(int score) {
    if (score <= 2) return 'Terrible';
    if (score <= 4) return 'Bad';
    if (score <= 6) return 'Okay';
    if (score <= 8) return 'Good';
    return 'Amazing';
  }
  static String getEmojiForScore(int score) {
    if (score <= 2) return '😫';
    if (score <= 4) return '😔';
    if (score <= 6) return '😐';
    if (score <= 8) return '🙂';
    return '🤩';
  }
}
