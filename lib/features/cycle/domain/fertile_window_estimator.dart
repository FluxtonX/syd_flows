import '../data/models/cycle_types.dart';

/// Pure domain service for fertile window estimation based on ovulation uncertainty (Phase 5).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
/// This is an estimation feature, NOT a contraceptive guarantee or medical diagnosis.
class FertileWindowEstimator {
  FertileWindowEstimator._();

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Estimates fertile window start/end boundaries, confidence, and basis.
  static FertileWindowEstimation estimate({
    required OvulationEstimation ovulationEst,
    CycleStatistics? stats,
  }) {
    // Sperm viability baseline = 5 days prior to ovulation date
    // Ovum viability baseline = 1 day after ovulation date
    final DateTime start = ovulationEst.earliestPossibleDate.subtract(const Duration(days: 5));
    final DateTime end = ovulationEst.latestPossibleDate.add(const Duration(days: 1));

    final String rangeDisplay = '${_formatShortDate(start)} – ${_formatShortDate(end)}';

    return FertileWindowEstimation(
      fertileWindowStart: start,
      fertileWindowEnd: end,
      confidence: ovulationEst.confidence,
      basis: ovulationEst.basis,
      rangeDisplay: rangeDisplay,
    );
  }

  static String _formatShortDate(DateTime date) {
    final m = _monthAbbr[date.month - 1];
    return '$m ${date.day}';
  }
}
