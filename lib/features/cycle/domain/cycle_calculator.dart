import '../data/models/cycle_types.dart';

/// CycleCalculator is a PURE DOMAIN SERVICE.
///
/// - No Flutter imports
/// - No Firestore imports
/// - No side effects
/// - Fully unit-testable
///
/// All cycle math lives here. UI and services consume the result.
///
/// CLUE-STYLE ALGORITHM:
///   - Phase is driven by ACTUAL logged flow, not a fixed periodLength.
///   - Menstrual phase = only days with a non-null/non-empty flow entry.
///   - Once flow logging stops, the next day immediately becomes Follicular.
///   - For days with no log yet (future within current cycle), if bleeding has
///     ended in this cycle, remaining days continue as Follicular/Ovulation/Luteal.
///   - For purely predicted future cycles, the adaptive average period length is
///     used to shade predicted Menstrual days.
class CycleCalculator {
  CycleCalculator._();

  // ── Public entry point ───────────────────────────────────────────────────

  /// Computes the current [CycleStatus] for [today] based on [settings].
  ///
  /// [confirmedPeriodStart] overrides [settings.lastPeriodStart] when a more
  /// recent confirmed period start is known.
  ///
  /// [allLogs] is the full map of `dateKey -> DayJournal` from Firestore.
  /// When provided, the actual number of bleeding days in the current cycle
  /// is used to determine the effective period length for phase computation.
  static CycleStatus compute({
    required CycleSettings settings,
    required DateTime today,
    DateTime? confirmedPeriodStart,
    Map<String, DayJournal>? allLogs,
  }) {
    final DateTime anchor = _resolveAnchor(
      settingsAnchor: settings.lastPeriodStart,
      confirmedAnchor: confirmedPeriodStart,
      today: today,
      cycleLength: settings.cycleLength,
    );

    final DateTime todayNorm = _dateOnly(today);
    final DateTime anchorNorm = _dateOnly(anchor);

    final int rawDiff = todayNorm.difference(anchorNorm).inDays;
    final int cycleDay = (rawDiff % settings.cycleLength) + 1;

    // Determine effective period length for current cycle.
    // If actual flow entries exist: use the actual bleeding day count.
    // Otherwise fall back to user's setting.
    final int effectivePeriodLength = _effectivePeriodLengthForCycle(
      cycleAnchor: anchorNorm,
      cycleLength: settings.cycleLength,
      today: todayNorm,
      allLogs: allLogs,
      fallback: settings.periodLength,
    );

    final CyclePhase phase = _computePhase(
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
    );

    final CyclePredictions predictions = _computePredictions(
      anchor: anchorNorm,
      today: todayNorm,
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
    );

    return CycleStatus(
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
      phase: phase,
      predictions: predictions,
      periodStartDate: anchorNorm,
    );
  }

  // ── Phase Boundaries ─────────────────────────────────────────────────────

  /// Computes which phase a [cycleDay] belongs to.
  ///
  /// Boundaries are DYNAMIC — derived from user's [cycleLength] and [periodLength].
  ///
  /// Menstrual : Day 1 to periodLength
  /// Follicular: Day periodLength+1 to ovulationDay-2
  /// Ovulation : Day ovulationDay-1 to ovulationDay+1
  /// Luteal    : Day ovulationDay+2 to cycleLength
  static CyclePhase _computePhase({
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
  }) {
    final int safePeriodLength = periodLength.clamp(1, 15);
    final int safeCycleLength = cycleLength.clamp(safePeriodLength + 5, 60);

    final int minOvulationDay = safePeriodLength + 2;
    final int maxOvulationDay = safeCycleLength - 1;
    final int rawOvulationDay = safeCycleLength - 14;

    final int ovulationDay = (minOvulationDay <= maxOvulationDay)
        ? rawOvulationDay.clamp(minOvulationDay, maxOvulationDay)
        : safePeriodLength + 2;

    final int follicularStart = safePeriodLength + 1;
    final int follicularEnd = ovulationDay - 2;

    final int ovulationStart = ovulationDay - 1;
    final int ovulationEnd = ovulationDay + 1;

    if (cycleDay <= safePeriodLength) return CyclePhase.menstrual;
    if (cycleDay >= follicularStart && cycleDay <= follicularEnd) {
      return CyclePhase.follicular;
    }
    if (cycleDay >= ovulationStart && cycleDay <= ovulationEnd) {
      return CyclePhase.ovulation;
    }
    return CyclePhase.luteal;
  }

  // ── Predictions ──────────────────────────────────────────────────────────

  static CyclePredictions _computePredictions({
    required DateTime anchor,
    required DateTime today,
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
  }) {
    final int safePeriodLength = periodLength.clamp(1, 15);
    final int safeCycleLength = cycleLength.clamp(safePeriodLength + 5, 60);

    final int daysUntilNextCycle = safeCycleLength - (cycleDay - 1);
    final DateTime nextPeriodStart = today.add(
      Duration(days: daysUntilNextCycle),
    );

    final int minOvulationDay = safePeriodLength + 2;
    final int maxOvulationDay = safeCycleLength - 1;
    final int rawOvulationDay = safeCycleLength - 14;

    final int ovulationDayNum = (minOvulationDay <= maxOvulationDay)
        ? rawOvulationDay.clamp(minOvulationDay, maxOvulationDay)
        : safePeriodLength + 2;

    final DateTime anchorOfCurrentCycle = anchor.add(
      Duration(days: -(cycleDay - 1)),
    );
    final DateTime ovulationDate = anchorOfCurrentCycle.add(
      Duration(days: ovulationDayNum - 1),
    );
    final DateTime fertileWindowStart = ovulationDate.subtract(
      const Duration(days: 5),
    );
    final DateTime fertileWindowEnd = ovulationDate.add(
      const Duration(days: 1),
    );

    if (ovulationDate.isBefore(today)) {
      final DateTime nextOvulationDate = ovulationDate.add(
        Duration(days: safeCycleLength),
      );
      final DateTime nextFertileStart = nextOvulationDate.subtract(
        const Duration(days: 5),
      );
      final DateTime nextFertileEnd = nextOvulationDate.add(
        const Duration(days: 1),
      );

      return CyclePredictions(
        nextPeriodStart: nextPeriodStart,
        fertileWindowStart: nextFertileStart,
        fertileWindowEnd: nextFertileEnd,
        ovulationDate: nextOvulationDate,
      );
    }

    return CyclePredictions(
      nextPeriodStart: nextPeriodStart,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      ovulationDate: ovulationDate,
    );
  }

  // ── Clue-Style: Effective Period Length ──────────────────────────────────

  /// Computes the effective period length for the current/active cycle.
  ///
  /// CLUE BEHAVIOUR:
  ///   - Count days within the cycle window [cycleAnchor, cycleAnchor+cycleLength)
  ///     that have a non-empty flow entry in [allLogs].
  ///   - Once bleeding has ended (last flow day is before today), the effective
  ///     period length is locked to actual bleeding day count.
  ///   - If no flow logged, returns [fallback].
  static int _effectivePeriodLengthForCycle({
    required DateTime cycleAnchor,
    required int cycleLength,
    required DateTime today,
    Map<String, DayJournal>? allLogs,
    required int fallback,
  }) {
    if (allLogs == null || allLogs.isEmpty) return fallback;

    final DateTime cycleEnd = cycleAnchor.add(Duration(days: cycleLength));

    int bleedingDays = 0;

    for (final entry in allLogs.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      final dateNorm = _dateOnly(date);

      // Within this cycle window and not after today
      if (!dateNorm.isBefore(cycleAnchor) &&
          dateNorm.isBefore(cycleEnd) &&
          !dateNorm.isAfter(today)) {
        final flow = entry.value.flow;
        if (flow != null && flow.isNotEmpty) {
          bleedingDays++;
        }
      }
    }

    if (bleedingDays == 0) return fallback;
    return bleedingDays.clamp(1, 15);
  }

  // ── Adaptive Period Length ───────────────────────────────────────────────

  /// Calculates rolling average period length from completed historical cycles.
  ///
  /// For each completed cycle, count days with a flow entry in [allLogs].
  /// Returns [fallbackLength] if no completed cycle data is available.
  /// Output is clamped to [2, 10].
  static int computeAdaptivePeriodLength({
    required List<DateTime> confirmedStarts,
    required Map<String, DayJournal> allLogs,
    required int fallbackLength,
    int cycleLength = 28,
  }) {
    if (confirmedStarts.isEmpty) return fallbackLength.clamp(2, 10);

    final sorted = List<DateTime>.from(confirmedStarts)
      ..sort((a, b) => a.compareTo(b));

    final DateTime todayNorm = _dateOnly(DateTime.now());
    final List<int> periodLengths = [];

    for (int i = 0; i < sorted.length; i++) {
      final DateTime cycleAnchor = _dateOnly(sorted[i]);
      final DateTime cycleEnd = (i < sorted.length - 1)
          ? _dateOnly(sorted[i + 1])
          : cycleAnchor.add(Duration(days: cycleLength));

      // Skip current/future cycle (not yet completed)
      if (!cycleEnd.isBefore(todayNorm)) continue;

      int bleedingDays = 0;
      for (final entry in allLogs.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final dateNorm = _dateOnly(date);
        if (!dateNorm.isBefore(cycleAnchor) && dateNorm.isBefore(cycleEnd)) {
          final flow = entry.value.flow;
          if (flow != null && flow.isNotEmpty) {
            bleedingDays++;
          }
        }
      }

      if (bleedingDays > 0) {
        periodLengths.add(bleedingDays.clamp(2, 10));
      }
    }

    if (periodLengths.isEmpty) return fallbackLength.clamp(2, 10);

    final double avg =
        periodLengths.reduce((a, b) => a + b) / periodLengths.length.toDouble();
    return avg.round().clamp(2, 10);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _resolveAnchor({
    required DateTime settingsAnchor,
    required DateTime? confirmedAnchor,
    required DateTime today,
    required int cycleLength,
  }) {
    final DateTime todayNorm = _dateOnly(today);
    final DateTime settingsNorm = _dateOnly(settingsAnchor);

    if (confirmedAnchor != null) {
      final DateTime confirmedNorm = _dateOnly(confirmedAnchor);
      if (!confirmedNorm.isAfter(todayNorm)) {
        return confirmedNorm;
      }
    }

    if (settingsNorm.isAfter(todayNorm)) {
      return todayNorm;
    }

    return settingsNorm;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── Adaptive Cycle Length ────────────────────────────────────────────────

  /// Calculates rolling average cycle length based on confirmed period records.
  ///
  /// Returns [fallbackLength] if fewer than 2 cycle intervals exist.
  /// Output is clamped to a realistic biological window [21, 45].
  static int computeAdaptiveCycleLength({
    required List<DateTime> confirmedStarts,
    required int fallbackLength,
  }) {
    if (confirmedStarts.length < 2) return fallbackLength.clamp(21, 45);

    final sorted = List<DateTime>.from(confirmedStarts)
      ..sort((a, b) => a.compareTo(b));

    final List<int> intervals = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final int diff = _dateOnly(
        sorted[i + 1],
      ).difference(_dateOnly(sorted[i])).inDays;
      if (diff >= 15 && diff <= 60) {
        intervals.add(diff);
      }
    }

    if (intervals.isEmpty) return fallbackLength.clamp(21, 45);

    final double avg =
        intervals.reduce((a, b) => a + b) / intervals.length.toDouble();
    return avg.round().clamp(21, 45);
  }

  // ── Calendar helpers ─────────────────────────────────────────────────────

  /// Returns the [CyclePhase] for any arbitrary calendar [date].
  ///
  /// CLUE-STYLE RULES (priority order):
  ///   1. If [date] has an actual flow entry in [allLogs] -> MENSTRUAL (hard rule).
  ///   2. If [date] falls in a known historical/current cycle window:
  ///      - Use actual bleeding day count as effectivePeriodLength.
  ///      - For future days in the LATEST cycle: use adaptivePeriodLength for
  ///        predicted next period shading.
  ///   3. Fallback: math-only phase using anchor and periodLength.
  static CyclePhase phaseForDate({
    required DateTime date,
    required DateTime anchor,
    required int cycleLength,
    required int periodLength,
    List<DateTime>? confirmedStarts,
    Map<String, DayJournal>? allLogs,
    int? adaptivePeriodLength,
  }) {
    final DateTime dateNorm = _dateOnly(date);
    final DateTime todayNorm = _dateOnly(DateTime.now());

    // ── Priority 1: Direct flow-log check ───────────────────────────────
    // If date has an actual flow entry it IS menstrual, regardless of anything.
    if (allLogs != null) {
      final y = dateNorm.year.toString();
      final m = dateNorm.month.toString().padLeft(2, '0');
      final d = dateNorm.day.toString().padLeft(2, '0');
      final key = '$y-$m-$d';
      final entry = allLogs[key];
      if (entry != null && entry.flow != null && entry.flow!.isNotEmpty) {
        return CyclePhase.menstrual;
      }
    }

    // ── Priority 2: Historical confirmed cycle windows ───────────────────
    if (confirmedStarts != null && confirmedStarts.isNotEmpty) {
      final sorted = List<DateTime>.from(confirmedStarts)
        ..sort((a, b) => a.compareTo(b));

      for (int i = 0; i < sorted.length; i++) {
        final DateTime cycleStart = _dateOnly(sorted[i]);
        final DateTime cycleEnd = (i < sorted.length - 1)
            ? _dateOnly(sorted[i + 1])
            : cycleStart.add(Duration(days: cycleLength));

        if (!dateNorm.isBefore(cycleStart) && dateNorm.isBefore(cycleEnd)) {
          final int rawCycleLen = cycleEnd.difference(cycleStart).inDays;
          final int effectiveLen = rawCycleLen >= 15
              ? rawCycleLen
              : cycleLength;

          // Clamp today to todayNorm when computing for future dates in current cycle
          final DateTime logCutoff = dateNorm.isAfter(todayNorm)
              ? todayNorm
              : dateNorm;

          // Count actual bleeding days in this cycle up to logCutoff
          final int effPeriodLen = _effectivePeriodLengthForCycle(
            cycleAnchor: cycleStart,
            cycleLength: effectiveLen,
            today: logCutoff,
            allLogs: allLogs,
            fallback: adaptivePeriodLength ?? periodLength,
          );

          // For future predicted days in the LATEST cycle window, use adaptive
          // period length so predicted next period gets correct shading
          final bool isLatestCycle = i == sorted.length - 1;
          final bool isFutureDay = dateNorm.isAfter(todayNorm);
          final int periodLenToUse =
              (isLatestCycle && isFutureDay && effPeriodLen == 0)
              ? (adaptivePeriodLength ?? periodLength)
              : effPeriodLen;

          final int cycleDay = dateNorm.difference(cycleStart).inDays + 1;
          return _computePhase(
            cycleDay: cycleDay,
            cycleLength: effectiveLen,
            periodLength: periodLenToUse,
          );
        }
      }
    }

    // ── Priority 3: Fallback math-only ──────────────────────────────────
    final DateTime anchorNorm = _dateOnly(anchor);

    if (dateNorm.isBefore(anchorNorm)) {
      final int rawDiff = anchorNorm.difference(dateNorm).inDays;
      final int daysBack = rawDiff % cycleLength;
      final int cycleDay = cycleLength - daysBack;
      return _computePhase(
        cycleDay: cycleDay,
        cycleLength: cycleLength,
        periodLength: adaptivePeriodLength ?? periodLength,
      );
    }

    final int rawDiff = dateNorm.difference(anchorNorm).inDays;
    final int cycleDay = (rawDiff % cycleLength) + 1;
    return _computePhase(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: adaptivePeriodLength ?? periodLength,
    );
  }

  /// Returns the cycle day for any arbitrary calendar [date].
  static int cycleDayForDate({
    required DateTime date,
    required DateTime anchor,
    required int cycleLength,
  }) {
    final DateTime dateNorm = _dateOnly(date);
    final DateTime anchorNorm = _dateOnly(anchor);
    final int rawDiff = dateNorm.difference(anchorNorm).inDays;
    return (rawDiff % cycleLength) + 1;
  }
}
