/// Pure domain helper for establishing bounded Firestore date query windows (Phase 14 Engine).
///
/// Prevents unbounded Firestore scans and N+1 queries by defining explicit date boundaries.
class BoundedCycleQueryBuilder {
  const BoundedCycleQueryBuilder._();

  /// Default historical query window duration (6 months / 180 days).
  static const int defaultHistoricalWindowDays = 180;

  /// Calculates the earliest start date for bounded cycle queries.
  static DateTime computeBoundedStartDate({
    required DateTime today,
    int maxLookbackDays = defaultHistoricalWindowDays,
  }) {
    final todayNorm = DateTime(today.year, today.month, today.day);
    return todayNorm.subtract(Duration(days: maxLookbackDays.clamp(30, 730)));
  }

  /// Formats date keys (YYYY-MM-DD) within a bounded date window.
  static List<String> generateBoundedDateKeys({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final List<String> keys = [];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final endNorm = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(endNorm)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      keys.add(key);
      current = current.add(const Duration(days: 1));
    }

    return keys;
  }
}
