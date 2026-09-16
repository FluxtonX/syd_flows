import '../data/models/cycle_types.dart';

/// Pure domain service for ovulation estimation with uncertainty range & basis (Phase 4).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
/// NEVER solves an impossible biological estimate by hard clamping to a false date.
class OvulationEstimator {
  OvulationEstimator._();

  /// Estimates ovulation date, earliest/latest possible range, confidence, and basis.
  static OvulationEstimation estimate({
    required DateTime anchor,
    required DateTime today,
    required int cycleLength,
    required int periodLength,
    CycleStatistics? stats,
  }) {
    final DateTime anchorNorm = DateTime(anchor.year, anchor.month, anchor.day);
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);

    final int safePeriodLength = periodLength.clamp(2, 14);
    final int safeCycleLength = cycleLength.clamp(15, 60);

    // Clinical benchmark: Luteal phase length is typically 14 days
    final int rawOvulationDay = safeCycleLength - 14;

    // Check biological viability: Follicular phase should ideally be >= 7 days
    final bool isBiologicallyViolated = rawOvulationDay <= safePeriodLength + 2;

    int finalOvulationDay = rawOvulationDay;
    if (isBiologicallyViolated) {
      finalOvulationDay = ((safePeriodLength + 1) + safeCycleLength) ~/ 2;
    }

    DateTime ovulationDate = anchorNorm.add(Duration(days: finalOvulationDay - 1));

    // If estimated ovulation date has passed, project forward into current cycle
    if (ovulationDate.isBefore(todayNorm)) {
      ovulationDate = ovulationDate.add(Duration(days: safeCycleLength));
    }

    // Uncertainty range margin scaling with standard deviation
    final double stdDev = stats?.cycleVariability ?? 2.0;
    final int marginDays = (stats != null && stats.cycleCount >= 2)
        ? stdDev.round().clamp(2, 5)
        : 3;

    final DateTime earliestDate = ovulationDate.subtract(Duration(days: marginDays));
    final DateTime latestDate = ovulationDate.add(Duration(days: marginDays));

    // Basis determination (never claims calendar estimate is user observation)
    final OvulationBasis basis = (stats != null && stats.cycleCount >= 3)
        ? OvulationBasis.historicalPattern
        : OvulationBasis.calendarEstimate;

    // Confidence evaluation: drops if biological assumptions are violated
    PredictionConfidence confidence;
    if (isBiologicallyViolated || stats == null || stats.cycleCount < 2) {
      confidence = PredictionConfidence.low;
    } else if (stats.cycleVariability <= 2.0 && stats.cycleCount >= 3) {
      confidence = PredictionConfidence.high;
    } else if (stats.cycleVariability <= 4.5) {
      confidence = PredictionConfidence.medium;
    } else {
      confidence = PredictionConfidence.low;
    }

    return OvulationEstimation(
      estimatedOvulationDate: ovulationDate,
      earliestPossibleDate: earliestDate,
      latestPossibleDate: latestDate,
      confidence: confidence,
      basis: basis,
    );
  }
}
