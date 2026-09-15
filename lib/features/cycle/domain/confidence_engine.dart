import '../data/models/cycle_types.dart';

/// Pure domain service for unified prediction confidence evaluation (Phase 6).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
/// Uses a deterministic rule matrix (NO machine learning / black-box models).
/// Never overrides actual user observations.
class ConfidenceEngine {
  ConfidenceEngine._();

  /// Evaluates unified confidence for a prediction given historical statistics and current cycle state.
  static ConfidenceScore evaluate({
    required CycleStatistics? stats,
    required int currentCycleDay,
    required int cycleLength,
    Map<String, DayJournal>? allLogs,
  }) {
    final int count = stats?.cycleCount ?? 0;
    final double stdDev = stats?.cycleVariability ?? 0.0;

    // Data completeness calculation for active cycle (logged days / current cycle day)
    int loggedDays = 0;
    if (allLogs != null && currentCycleDay > 0) {
      for (final entry in allLogs.entries) {
        if (!entry.value.isEmpty) {
          loggedDays++;
        }
      }
    }
    final double completeness = currentCycleDay > 0
        ? (loggedDays / currentCycleDay).clamp(0.0, 1.0)
        : 0.0;

    final int deviation = currentCycleDay > cycleLength ? currentCycleDay - cycleLength : 0;

    // Deterministic Rule Evaluation Matrix
    PredictionConfidence rating;
    String explanation;

    if (count < 2) {
      rating = PredictionConfidence.insufficient;
      explanation = 'Fewer than 2 completed cycles recorded.';
    } else if (stdDev <= 2.0 && count >= 3 && deviation <= 3) {
      rating = PredictionConfidence.high;
      explanation = 'Highly consistent history ($count cycles, variability ±${stdDev.toStringAsFixed(1)} days).';
    } else if (stdDev <= 4.5 && deviation <= 5) {
      rating = PredictionConfidence.medium;
      explanation = 'Moderate cycle consistency ($count cycles, variability ±${stdDev.toStringAsFixed(1)} days).';
    } else {
      rating = PredictionConfidence.low;
      explanation = 'Variable cycle history ($count cycles, variability ±${stdDev.toStringAsFixed(1)} days).';
    }

    return ConfidenceScore(
      rating: rating,
      cycleCount: count,
      variability: stdDev,
      dataCompleteness: completeness,
      currentCycleDeviation: deviation,
      explanation: explanation,
    );
  }
}
