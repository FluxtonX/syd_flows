import '../data/models/cycle_types.dart';

/// Pure domain service for next period prediction with uncertainty range & confidence (Phase 3).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
class NextPeriodPredictor {
  NextPeriodPredictor._();

  static const List<String> _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Predicts the next period start date, uncertainty range, and confidence.
  static PeriodPrediction predict({
    required DateTime anchor,
    required DateTime today,
    required int cycleLength,
    CycleStatistics? stats,
  }) {
    final DateTime anchorNorm = DateTime(anchor.year, anchor.month, anchor.day);
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);

    // 1. Estimated Cycle Length
    final double estimatedCycleLength =
        (stats != null && stats.weightedRecencyLength != null)
        ? stats.weightedRecencyLength!
        : (stats != null && stats.medianCycleLength != null)
        ? stats.medianCycleLength!
        : cycleLength.toDouble();

    final int roundedCycleLen = estimatedCycleLength.round().clamp(15, 60);

    // 2. Projected Next Period Date
    DateTime predictedDate = anchorNorm.add(Duration(days: roundedCycleLen));

    // If predicted date has passed in history, project forward to next upcoming cycle
    if (predictedDate.isBefore(todayNorm)) {
      final int daysDiff = todayNorm.difference(anchorNorm).inDays;
      final int cyclesAhead = (daysDiff ~/ roundedCycleLen) + 1;
      predictedDate = anchorNorm.add(
        Duration(days: roundedCycleLen * cyclesAhead),
      );
    }

    // 3. Margin & Range Calculation
    final double stdDev = stats?.cycleVariability ?? 2.0;
    final int marginDays = (stats != null && stats.cycleCount >= 2)
        ? stdDev.round().clamp(2, 6)
        : 3; // Default 3 days margin when history is insufficient

    final DateTime earliestDate = predictedDate.subtract(
      Duration(days: marginDays),
    );
    final DateTime latestDate = predictedDate.add(Duration(days: marginDays));

    // 4. Confidence Evaluation
    final PredictionConfidence confidence = _evaluateConfidence(stats);

    // 5. Range Display String (e.g., "Sep 26 – Sep 30")
    final String rangeDisplay =
        '${_formatShortDate(earliestDate)} – ${_formatShortDate(latestDate)}';

    return PeriodPrediction(
      predictedDate: predictedDate,
      earliestDate: earliestDate,
      latestDate: latestDate,
      confidence: confidence,
      rangeDisplay: rangeDisplay,
    );
  }

  static PredictionConfidence _evaluateConfidence(CycleStatistics? stats) {
    if (stats == null || stats.cycleCount < 2) {
      return PredictionConfidence.insufficient;
    }
    if (stats.cycleVariability <= 2.0 && stats.cycleCount >= 3) {
      return PredictionConfidence.high;
    }
    if (stats.cycleVariability <= 4.5) {
      return PredictionConfidence.medium;
    }
    return PredictionConfidence.low;
  }

  static String _formatShortDate(DateTime date) {
    final m = _monthAbbr[date.month - 1];
    return '$m ${date.day}';
  }
}
