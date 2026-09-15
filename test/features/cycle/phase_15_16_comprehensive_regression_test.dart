import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';

void main() {
  group('Phase 15 & Phase 16 — Comprehensive Edge Cases & Regression Verification', () {
    test('Outlier cycle handling (27, 28, 29, 55 days) does not corrupt median', () {
      final base = DateTime(2026, 1, 1);
      final starts = [
        base,
        base.add(const Duration(days: 27)),
        base.add(const Duration(days: 55)), // +28
        base.add(const Duration(days: 84)), // +29
        base.add(const Duration(days: 139)), // +55 (Outlier!)
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      // Median should remain robust (~28.5) and not be corrupted by 55
      expect(stats.medianCycleLength, closeTo(28.5, 1.0));
      expect(stats.maximumCycleLength, equals(55));
    });

    test('Short cycle sequence (20, 21, 22 days) calculates correct statistics', () {
      final base = DateTime(2026, 1, 1);
      final starts = [
        base,
        base.add(const Duration(days: 20)),
        base.add(const Duration(days: 41)), // +21
        base.add(const Duration(days: 63)), // +22
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      expect(stats.minimumCycleLength, equals(20));
      expect(stats.medianCycleLength, equals(21.0));
    });

    test('Long cycle sequence (46, 48, 50 days) calculates correct statistics', () {
      final base = DateTime(2026, 1, 1);
      final starts = [
        base,
        base.add(const Duration(days: 46)),
        base.add(const Duration(days: 94)), // +48
        base.add(const Duration(days: 144)), // +50
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      expect(stats.maximumCycleLength, equals(50));
      expect(stats.medianCycleLength, equals(48.0));
    });

    test('Month boundary transitions (January -> February -> March)', () {
      final janStart = DateTime(2026, 1, 15);
      final settings = CycleSettings(
        lastPeriodStart: janStart,
        cycleLength: 28,
        periodLength: 5,
      );

      // Today in February
      final febToday = DateTime(2026, 2, 10);
      final febStatus = CycleCalculator.compute(
        settings: settings,
        today: febToday,
      );

      expect(febStatus.predictions.nextPeriodStart, equals(DateTime(2026, 2, 12)));

      // Today in March
      final marToday = DateTime(2026, 3, 15);
      final marStatus = CycleCalculator.compute(
        settings: settings,
        today: marToday,
      );

      expect(marStatus.predictions.nextPeriodStart, isNotNull);
    });

    test('Leap year boundary (Feb 29, 2028)', () {
      final leapStart = DateTime(2028, 2, 1);
      final settings = CycleSettings(
        lastPeriodStart: leapStart,
        cycleLength: 28,
        periodLength: 5,
      );

      final leapToday = DateTime(2028, 2, 29); // Day 29 of leap February
      final status = CycleCalculator.compute(
        settings: settings,
        today: leapToday,
      );

      expect(status.cycleDay, equals(29));
      expect(status.predictions.nextPeriodStart, equals(DateTime(2028, 2, 29)));
    });
  });
}
