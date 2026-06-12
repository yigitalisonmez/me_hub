import 'reminder_feature.dart';

class ReminderTime {
  final int hour;
  final int minute;

  const ReminderTime({required this.hour, required this.minute});

  int get minutesSinceMidnight => hour * 60 + minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory ReminderTime.fromJson(
    Object? value, {
    required ReminderTime fallback,
  }) {
    if (value is! Map) return fallback;
    final hour = value['hour'];
    final minute = value['minute'];
    if (hour is! int ||
        minute is! int ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }
    return ReminderTime(hour: hour, minute: minute);
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

class ReminderPreferences {
  static const schemaVersion = 1;

  final bool masterEnabled;
  final Map<ReminderFeature, bool> enabledFeatures;
  final Map<ReminderFeature, ReminderTime> featureTimes;
  final ReminderTime waterStart;
  final ReminderTime waterEnd;
  final int waterIntervalHours;

  const ReminderPreferences({
    required this.masterEnabled,
    required this.enabledFeatures,
    required this.featureTimes,
    required this.waterStart,
    required this.waterEnd,
    required this.waterIntervalHours,
  });

  factory ReminderPreferences.defaults({bool masterEnabled = false}) {
    return ReminderPreferences(
      masterEnabled: masterEnabled,
      enabledFeatures: {
        for (final feature in ReminderFeature.values) feature: false,
      },
      featureTimes: const {
        ReminderFeature.mood: ReminderTime(hour: 20, minute: 0),
        ReminderFeature.gratitudeMorning: ReminderTime(hour: 8, minute: 0),
        ReminderFeature.gratitudeEvening: ReminderTime(hour: 20, minute: 30),
        ReminderFeature.breathing: ReminderTime(hour: 18, minute: 0),
        ReminderFeature.affirmations: ReminderTime(hour: 9, minute: 0),
        ReminderFeature.todo: ReminderTime(hour: 18, minute: 30),
        ReminderFeature.challenges: ReminderTime(hour: 19, minute: 0),
        ReminderFeature.weeklyInsights: ReminderTime(hour: 20, minute: 0),
      },
      waterStart: const ReminderTime(hour: 8, minute: 0),
      waterEnd: const ReminderTime(hour: 20, minute: 0),
      waterIntervalHours: 2,
    );
  }

  bool isEnabled(ReminderFeature feature) => enabledFeatures[feature] ?? false;

  ReminderTime timeFor(ReminderFeature feature) {
    return featureTimes[feature] ??
        ReminderPreferences.defaults().featureTimes[feature] ??
        const ReminderTime(hour: 9, minute: 0);
  }

  ReminderPreferences copyWith({
    bool? masterEnabled,
    Map<ReminderFeature, bool>? enabledFeatures,
    Map<ReminderFeature, ReminderTime>? featureTimes,
    ReminderTime? waterStart,
    ReminderTime? waterEnd,
    int? waterIntervalHours,
  }) {
    return ReminderPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      featureTimes: featureTimes ?? this.featureTimes,
      waterStart: waterStart ?? this.waterStart,
      waterEnd: waterEnd ?? this.waterEnd,
      waterIntervalHours: waterIntervalHours ?? this.waterIntervalHours,
    );
  }

  ReminderPreferences setFeatureEnabled(ReminderFeature feature, bool enabled) {
    return copyWith(enabledFeatures: {...enabledFeatures, feature: enabled});
  }

  ReminderPreferences setFeatureTime(
    ReminderFeature feature,
    ReminderTime time,
  ) {
    return copyWith(featureTimes: {...featureTimes, feature: time});
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'masterEnabled': masterEnabled,
    'enabledFeatures': {
      for (final entry in enabledFeatures.entries)
        entry.key.storageKey: entry.value,
    },
    'featureTimes': {
      for (final entry in featureTimes.entries)
        entry.key.storageKey: entry.value.toJson(),
    },
    'waterStart': waterStart.toJson(),
    'waterEnd': waterEnd.toJson(),
    'waterIntervalHours': waterIntervalHours,
  };

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    final defaults = ReminderPreferences.defaults(
      masterEnabled: json['masterEnabled'] == true,
    );
    final enabledJson = json['enabledFeatures'];
    final timesJson = json['featureTimes'];

    final enabled = <ReminderFeature, bool>{
      for (final feature in ReminderFeature.values)
        feature: enabledJson is Map && enabledJson[feature.storageKey] is bool
            ? enabledJson[feature.storageKey] as bool
            : defaults.isEnabled(feature),
    };

    final times = <ReminderFeature, ReminderTime>{
      for (final feature in defaults.featureTimes.keys)
        feature: ReminderTime.fromJson(
          timesJson is Map ? timesJson[feature.storageKey] : null,
          fallback: defaults.timeFor(feature),
        ),
    };

    final interval = json['waterIntervalHours'];
    return ReminderPreferences(
      masterEnabled: json['masterEnabled'] == true,
      enabledFeatures: enabled,
      featureTimes: times,
      waterStart: ReminderTime.fromJson(
        json['waterStart'],
        fallback: defaults.waterStart,
      ),
      waterEnd: ReminderTime.fromJson(
        json['waterEnd'],
        fallback: defaults.waterEnd,
      ),
      waterIntervalHours: interval is int && const [2, 3, 4].contains(interval)
          ? interval
          : defaults.waterIntervalHours,
    );
  }
}
