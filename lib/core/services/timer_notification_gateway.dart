abstract interface class TimerNotificationGateway {
  Future<void> scheduleTimerCompletion({
    required DateTime scheduledAt,
    required String title,
    required String body,
  });

  Future<void> cancelTimerCompletion();
}
