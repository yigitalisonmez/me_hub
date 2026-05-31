import 'package:flutter/material.dart';

/// Returns constant Material icons for stored code points.
///
/// Constructing IconData dynamically breaks Flutter release icon tree shaking.
/// Keep this list in sync with challenge templates and badge definitions.
IconData materialIconFromCodePoint(int codePoint) {
  if (codePoint == Icons.air.codePoint) return Icons.air;
  if (codePoint == Icons.calendar_month.codePoint) return Icons.calendar_month;
  if (codePoint == Icons.check_circle.codePoint) return Icons.check_circle;
  if (codePoint == Icons.emoji_events.codePoint) return Icons.emoji_events;
  if (codePoint == Icons.favorite.codePoint) return Icons.favorite;
  if (codePoint == Icons.flag.codePoint) return Icons.flag;
  if (codePoint == Icons.local_drink.codePoint) return Icons.local_drink;
  if (codePoint == Icons.local_fire_department.codePoint) {
    return Icons.local_fire_department;
  }
  if (codePoint == Icons.military_tech.codePoint) return Icons.military_tech;
  if (codePoint == Icons.mood.codePoint) return Icons.mood;
  if (codePoint == Icons.nightlight_round.codePoint) {
    return Icons.nightlight_round;
  }
  if (codePoint == Icons.record_voice_over.codePoint) {
    return Icons.record_voice_over;
  }
  if (codePoint == Icons.repeat.codePoint) return Icons.repeat;
  if (codePoint == Icons.sports_score.codePoint) return Icons.sports_score;
  if (codePoint == Icons.star.codePoint) return Icons.star;
  if (codePoint == Icons.task_alt.codePoint) return Icons.task_alt;
  if (codePoint == Icons.water.codePoint) return Icons.water;
  if (codePoint == Icons.water_drop.codePoint) return Icons.water_drop;
  if (codePoint == Icons.waves.codePoint) return Icons.waves;
  if (codePoint == Icons.wb_sunny.codePoint) return Icons.wb_sunny;
  if (codePoint == Icons.whatshot.codePoint) return Icons.whatshot;
  if (codePoint == Icons.workspace_premium.codePoint) {
    return Icons.workspace_premium;
  }

  return Icons.emoji_events;
}
