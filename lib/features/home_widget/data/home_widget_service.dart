import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:me_hub/features/home_widget/presentation/widgets/me_hub_widget.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.me_hub'; // For iOS sharing
  static const String androidWidgetName = 'MeHubWidgetProvider';

  Future<void> updateWidget({
    int? waterIntake,
    int? waterGoal,
    String? moodEmoji,
    String? moodLabel,
  }) async {
    try {
      // Fetch existing data if not provided
      final currentWaterIntake = waterIntake ?? await HomeWidget.getWidgetData<int>('water_intake') ?? 0;
      final currentWaterGoal = waterGoal ?? await HomeWidget.getWidgetData<int>('water_goal') ?? 2000;
      final currentMoodEmoji = moodEmoji ?? await HomeWidget.getWidgetData<String>('mood_emoji') ?? '😐';
      final currentMoodLabel = moodLabel ?? await HomeWidget.getWidgetData<String>('mood_label') ?? 'Neutral';

      // Save new data
      if (waterIntake != null) await HomeWidget.saveWidgetData<int>('water_intake', waterIntake);
      if (waterGoal != null) await HomeWidget.saveWidgetData<int>('water_goal', waterGoal);
      if (moodEmoji != null) await HomeWidget.saveWidgetData<String>('mood_emoji', moodEmoji);
      if (moodLabel != null) await HomeWidget.saveWidgetData<String>('mood_label', moodLabel);
      
      // Render Flutter widget to image
      await HomeWidget.renderFlutterWidget(
        MeHubWidget(
          waterIntake: currentWaterIntake,
          waterGoal: currentWaterGoal,
          moodEmoji: currentMoodEmoji,
          moodLabel: currentMoodLabel,
        ),
        key: 'me_hub_widget_image',
        logicalSize: const Size(338, 158), // Medium widget size
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'MeHubWidget',
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }
}
