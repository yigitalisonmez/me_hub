enum ReminderFeature {
  water,
  mood,
  gratitudeMorning,
  gratitudeEvening,
  breathing,
  affirmations,
  todo,
  challenges,
  weeklyInsights,
}

extension ReminderFeatureX on ReminderFeature {
  String get storageKey => name;

  String get namespace => 'feature:$name';

  String get title {
    switch (this) {
      case ReminderFeature.water:
        return 'Water';
      case ReminderFeature.mood:
        return 'Mood';
      case ReminderFeature.gratitudeMorning:
        return 'Morning gratitude';
      case ReminderFeature.gratitudeEvening:
        return 'Evening gratitude';
      case ReminderFeature.breathing:
        return 'Breathing';
      case ReminderFeature.affirmations:
        return 'Affirmations';
      case ReminderFeature.todo:
        return 'Tasks';
      case ReminderFeature.challenges:
        return 'Challenges';
      case ReminderFeature.weeklyInsights:
        return 'Weekly insights';
    }
  }
}
