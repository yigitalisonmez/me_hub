enum ReminderRepeat { none, daily, weekly }

class ReminderRequest {
  final String logicalKey;
  final String namespace;
  final String title;
  final String body;
  final String payload;
  final DateTime scheduledAt;
  final ReminderRepeat repeat;
  final bool exact;

  const ReminderRequest({
    required this.logicalKey,
    required this.namespace,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledAt,
    this.repeat = ReminderRepeat.none,
    this.exact = false,
  });
}
