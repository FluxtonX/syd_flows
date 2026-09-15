import '../data/models/cycle_types.dart';

/// Notification trigger decision outcome (Phase 13).
class NotificationSafetyDecision {
  final bool shouldTrigger;
  final String reason;

  const NotificationSafetyDecision({
    required this.shouldTrigger,
    required this.reason,
  });

  static const NotificationSafetyDecision allowed = NotificationSafetyDecision(
    shouldTrigger: true,
    reason: 'Notification criteria met safely.',
  );
}

/// Pure domain service enforcing notification safety & anti-spam constraints (Phase 13 Engine).
///
/// Prevents stale predictions or low-confidence estimates from triggering user notification spam.
class NotificationSafetyEvaluator {
  const NotificationSafetyEvaluator._();

  static NotificationSafetyDecision evaluatePeriodReminder({
    required CycleStatus status,
    required DateTime targetNotificationDate,
    bool isEventAlreadyRecorded = false,
  }) {
    if (isEventAlreadyRecorded) {
      return const NotificationSafetyDecision(
        shouldTrigger: false,
        reason: 'Event has already been recorded by the user.',
      );
    }

    final predictions = status.predictions;
    if (predictions.confidence == PredictionConfidence.insufficient ||
        predictions.confidence == PredictionConfidence.low) {
      return NotificationSafetyDecision(
        shouldTrigger: false,
        reason: 'Prediction confidence is too low (${predictions.confidence.label}).',
      );
    }

    if (status.estimatedPhase?.isStale == true) {
      return const NotificationSafetyDecision(
        shouldTrigger: false,
        reason: 'Prediction is stale and outside safe window.',
      );
    }

    if (status.stateCategory == CycleStateCategory.late && status.overdueDays > 7) {
      return const NotificationSafetyDecision(
        shouldTrigger: false,
        reason: 'Cycle is severely overdue; period reminder suppressed.',
      );
    }

    return NotificationSafetyDecision.allowed;
  }
}
