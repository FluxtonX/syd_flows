import '../data/models/cycle_types.dart';

/// Value object representing evaluated cycle state & decayed prediction confidence (Phase 8 Engine).
class CycleStateEvaluation {
  final CycleStateCategory category;
  final int overdueDays;
  final PredictionConfidence adjustedConfidence;

  const CycleStateEvaluation({
    required this.category,
    required this.overdueDays,
    required this.adjustedConfidence,
  });
}

/// Pure domain service for late, missed, and stale prediction handling (Phase 8 Engine).
///
/// Ensures prediction confidence explicitly decays when predicted periods are overdue,
/// rather than endlessly projecting active phases without confidence reduction.
class CycleStateEvaluator {
  const CycleStateEvaluator._();

  static CycleStateEvaluation evaluate({
    required DateTime currentDate,
    required DateTime predictedPeriodStart,
    required int currentCycleDay,
    required int expectedCycleLength,
    required PredictionConfidence baseConfidence,
    required RegularityClass regularityClass,
    bool isBleeding = false,
  }) {
    // 1. Confirmed period state (user is actively logging bleeding)
    if (isBleeding) {
      return CycleStateEvaluation(
        category: CycleStateCategory.confirmed,
        overdueDays: 0,
        adjustedConfidence: baseConfidence,
      );
    }

    // 2. Insufficient data state
    if (regularityClass == RegularityClass.insufficientData) {
      final overdue = currentCycleDay > expectedCycleLength
          ? currentCycleDay - expectedCycleLength
          : 0;
      return CycleStateEvaluation(
        category: CycleStateCategory.insufficientData,
        overdueDays: overdue,
        adjustedConfidence: PredictionConfidence.insufficient,
      );
    }

    // 3. Irregular cycle state
    if (regularityClass == RegularityClass.highlyVariable) {
      final overdue = currentCycleDay > expectedCycleLength
          ? currentCycleDay - expectedCycleLength
          : 0;
      return CycleStateEvaluation(
        category: CycleStateCategory.irregular,
        overdueDays: overdue,
        adjustedConfidence: PredictionConfidence.low,
      );
    }

    // Normalize dates to midnight for consistent day calculations
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final expectedStart = DateTime(
      predictedPeriodStart.year,
      predictedPeriodStart.month,
      predictedPeriodStart.day,
    );

    final daysDiff = today.difference(expectedStart).inDays;
    final cycleDayOverdue = currentCycleDay > expectedCycleLength
        ? currentCycleDay - expectedCycleLength
        : 0;
    final overdueDays = daysDiff > 0
        ? daysDiff
        : (cycleDayOverdue > 0 ? cycleDayOverdue : 0);

    // 4. Late / Missed period state
    if (overdueDays > 0) {
      final PredictionConfidence decayedConfidence;
      if (overdueDays <= 3) {
        decayedConfidence = _decayConfidence(baseConfidence, 1);
      } else if (overdueDays <= 7) {
        decayedConfidence = _decayConfidence(baseConfidence, 2);
      } else {
        decayedConfidence = PredictionConfidence.insufficient;
      }

      return CycleStateEvaluation(
        category: CycleStateCategory.late,
        overdueDays: overdueDays,
        adjustedConfidence: decayedConfidence,
      );
    }

    // 5. Expected period state (within 2 days prior to predicted period start)
    if (daysDiff >= -2 && daysDiff <= 0) {
      return CycleStateEvaluation(
        category: CycleStateCategory.expected,
        overdueDays: 0,
        adjustedConfidence: baseConfidence,
      );
    }

    // 6. Active ongoing cycle state
    return CycleStateEvaluation(
      category: CycleStateCategory.active,
      overdueDays: 0,
      adjustedConfidence: baseConfidence,
    );
  }

  /// Helper to decay confidence rating by a given number of steps.
  static PredictionConfidence _decayConfidence(
    PredictionConfidence original,
    int steps,
  ) {
    const levels = [
      PredictionConfidence.insufficient,
      PredictionConfidence.low,
      PredictionConfidence.medium,
      PredictionConfidence.high,
    ];

    final currentIndex = levels.indexOf(original);
    if (currentIndex == -1) return PredictionConfidence.insufficient;
    final targetIndex = (currentIndex - steps).clamp(0, levels.length - 1);
    return levels[targetIndex];
  }
}
