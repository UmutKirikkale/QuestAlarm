/// `users/{uid}/active_event_progress/{eventId}` kaydı.
class EventProgress {
  const EventProgress({
    required this.eventId,
    required this.currentProgress,
    required this.completed,
    required this.rewardClaimed,
    this.enrolled = false,
  });

  final String eventId;
  final int currentProgress;
  final bool completed;
  final bool rewardClaimed;

  /// Oyuncu etkinliğe katıldıysa sabah zaferleri ilerlemeyi artırır.
  final bool enrolled;

  bool get isActiveEnrollment => enrolled && !rewardClaimed;

  bool canClaimReward(int targetCount) =>
      !rewardClaimed && currentProgress >= targetCount;

  double progressRatio(int targetCount) {
    if (targetCount <= 0) return 0;
    return (currentProgress / targetCount).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'currentProgress': currentProgress,
      'completed': completed,
      'rewardClaimed': rewardClaimed,
      'enrolled': enrolled,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory EventProgress.fromMap(String eventId, Map<String, dynamic> map) {
    final progress = (map['currentProgress'] as num?)?.toInt() ?? 0;
    final enrolledRaw = map['enrolled'] as bool?;
    return EventProgress(
      eventId: eventId,
      currentProgress: progress,
      completed: map['completed'] as bool? ?? false,
      rewardClaimed: map['rewardClaimed'] as bool? ?? false,
      enrolled: enrolledRaw ?? progress > 0,
    );
  }

  static EventProgress empty(String eventId) => EventProgress(
        eventId: eventId,
        currentProgress: 0,
        completed: false,
        rewardClaimed: false,
        enrolled: false,
      );
}
