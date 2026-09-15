import 'dart:math' as math;
import '../data/models/cycle_types.dart';

/// Pure domain service for historical cycle statistical analysis (Phase 2).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
/// Preserves actual historical observations without modifying or clamping them.
class HistoricalCycleAnalyzer {
  HistoricalCycleAnalyzer._();

  /// Analyzes a chronological list of confirmed period start dates.
  static CycleStatistics analyze({
    required List<DateTime> confirmedStarts,
    required int fallbackLength,
  }) {
    if (confirmedStarts.length < 2) {
      return CycleStatistics.empty(fallbackLength);
    }

    // Sort ascending chronologically
    final sorted = List<DateTime>.from(confirmedStarts)
      ..sort((a, b) => a.compareTo(b));

    // Calculate actual unclamped cycle intervals
    final List<int> rawIntervals = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final int diff = _dateOnly(
        sorted[i + 1],
      ).difference(_dateOnly(sorted[i])).inDays;
      // Valid interval filter: between 10 and 90 days (keeps actual outlier values like 18 or 55 intact)
      if (diff >= 10 && diff <= 90) {
        rawIntervals.add(diff);
      }
    }

    if (rawIntervals.isEmpty) {
      return CycleStatistics.empty(fallbackLength);
    }

    final int count = rawIntervals.length;

    // 1. Median Calculation
    final sortedIntervals = List<int>.from(rawIntervals)..sort();
    final double median = (count % 2 == 1)
        ? sortedIntervals[count ~/ 2].toDouble()
        : (sortedIntervals[(count ~/ 2) - 1] + sortedIntervals[count ~/ 2]) /
              2.0;

    // 2. Mean Calculation
    final double mean = rawIntervals.reduce((a, b) => a + b) / count.toDouble();

    // 3. Min & Max Calculation
    final int minLen = sortedIntervals.first;
    final int maxLen = sortedIntervals.last;

    // 4. Cycle Variability (Standard Deviation)
    final double variability = _calculateStdDev(rawIntervals, mean);

    // 5. Regularity Classification
    final RegularityClass regularity = _classifyRegularity(count, variability);

    // 6. Weighted Recency Estimator (Exponential weighting for recent cycles)
    final double weightedRecency = _calculateWeightedRecency(rawIntervals);

    return CycleStatistics(
      cycleCount: count,
      medianCycleLength: median,
      meanCycleLength: mean,
      minimumCycleLength: minLen,
      maximumCycleLength: maxLen,
      cycleVariability: variability,
      recentCycleLengths: List<int>.unmodifiable(rawIntervals),
      regularityClass: regularity,
      weightedRecencyLength: weightedRecency,
    );
  }

  static double _calculateStdDev(List<int> values, double mean) {
    if (values.length <= 1) return 0.0;
    double sumOfSquaredDiffs = 0.0;
    for (final val in values) {
      final diff = val - mean;
      sumOfSquaredDiffs += diff * diff;
    }
    final variance = sumOfSquaredDiffs / (values.length - 1);
    return math.sqrt(variance);
  }

  static RegularityClass _classifyRegularity(int count, double stdDev) {
    if (count < 2) return RegularityClass.insufficientData;
    if (stdDev <= 2.0) return RegularityClass.regular;
    if (stdDev <= 4.0) return RegularityClass.slightlyVariable;
    if (stdDev <= 7.0) return RegularityClass.variable;
    return RegularityClass.highlyVariable;
  }

  /// Calculates a weighted recency estimator giving more weight to recent cycles.
  /// Uses recent 6 cycles max.
  static double _calculateWeightedRecency(List<int> intervals) {
    if (intervals.isEmpty) return 28.0;
    // Take up to last 6 cycles (most recent at end)
    final recent = intervals.length > 6
        ? intervals.sublist(intervals.length - 6)
        : intervals;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < recent.length; i++) {
      // Linear-quadratic weight boost for recent items: (i + 1)^1.5
      final weight = math.pow(i + 1, 1.5).toDouble();
      weightedSum += recent[i] * weight;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
