import 'package:hive_flutter/hive_flutter.dart';

part 'gratitude_item.g.dart';

/// A single gratitude item with depth questions
@HiveType(typeId: 41)
class GratitudeItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content; // "Neye şükrediyorsun?"

  @HiveField(2)
  final String? whyContent; // "Bunun hayatındaki değeri nedir?"

  @HiveField(3)
  final String? feelingContent; // "Sana ne hissettirdi?"

  @HiveField(4)
  final List<String>? emotionTags; // ["Huzur", "Coşku", "Güven"]

  @HiveField(5)
  final String? voiceRecordingPath; // Path to audio file (optional)

  @HiveField(6)
  final int createdAtTimestamp;

  const GratitudeItem({
    required this.id,
    required this.content,
    this.whyContent,
    this.feelingContent,
    this.emotionTags,
    this.voiceRecordingPath,
    required this.createdAtTimestamp,
  });

  /// Get DateTime from timestamp
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp);

  /// Check if depth questions are answered
  bool get hasDepthAnswers => whyContent != null || feelingContent != null;

  /// Check if has emotion tags
  bool get hasEmotionTags => emotionTags != null && emotionTags!.isNotEmpty;

  /// Check if has voice recording
  bool get hasVoiceRecording => voiceRecordingPath != null;

  /// Create a new item with generated ID
  factory GratitudeItem.create({
    required String content,
    String? whyContent,
    String? feelingContent,
    List<String>? emotionTags,
    String? voiceRecordingPath,
  }) {
    return GratitudeItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      whyContent: whyContent,
      feelingContent: feelingContent,
      emotionTags: emotionTags,
      voiceRecordingPath: voiceRecordingPath,
      createdAtTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  GratitudeItem copyWith({
    String? id,
    String? content,
    String? whyContent,
    String? feelingContent,
    List<String>? emotionTags,
    String? voiceRecordingPath,
    int? createdAtTimestamp,
  }) {
    return GratitudeItem(
      id: id ?? this.id,
      content: content ?? this.content,
      whyContent: whyContent ?? this.whyContent,
      feelingContent: feelingContent ?? this.feelingContent,
      emotionTags: emotionTags ?? this.emotionTags,
      voiceRecordingPath: voiceRecordingPath ?? this.voiceRecordingPath,
      createdAtTimestamp: createdAtTimestamp ?? this.createdAtTimestamp,
    );
  }
}
