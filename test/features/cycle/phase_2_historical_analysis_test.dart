import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';

void main() {
  group('Phase 2 — Historical Cycle Analysis Engine', () {
    test(
      '1. Insufficient data (<2 confirmed starts) returns insufficientData regularity',
      () {
        final starts = [DateTime(2026, 9, 10)];
        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: starts,
          fallbackLength: 28,
        );

        expect(stats.cycleCount, equals(0));
        expect(stats.regularityClass, equals(RegularityClass.insufficientData));
        expect(stats.recentCycleLengths, isEmpty);
      },
    );

    test(
      '2. Regular cycles (28, 28, 28) computes zero variability and Regular class',
      () {
        final starts = [
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 29), // 28 days
          DateTime(2026, 6, 26), // 28 days
          DateTime(2026, 7, 24), // 28 days
        ];

        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: starts,
          fallbackLength: 28,
        );

        expect(stats.cycleCount, equals(3));
        expect(stats.medianCycleLength, equals(28.0));
        expect(stats.meanCycleLength, equals(28.0));
        expect(stats.minimumCycleLength, equals(28));
        expect(stats.maximumCycleLength, equals(28));
        expect(stats.cycleVariability, equals(0.0));
        expect(stats.regularityClass, equals(RegularityClass.regular));
        expect(stats.recentCycleLengths, equals([28, 28, 28]));
      },
    );

    test(
      '3. Actual short cycle (18 days) remains 18 in recentCycleLengths without forced clamping',
      () {
        final starts = [
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 19), // 18 days
          DateTime(2026, 6, 16), // 28 days
        ];

        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: starts,
          fallbackLength: 28,
        );

        expect(stats.recentCycleLengths, contains(18));
        expect(stats.minimumCycleLength, equals(18));
      },
    );

    test(
      '4. Variable cycles compute correct median, mean, min, max, and variability',
      () {
        final starts = [
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 24), // 23 days
          DateTime(2026, 2, 27), // 34 days
          DateTime(2026, 3, 26), // 27 days
          DateTime(2026, 5, 4), // 39 days
          DateTime(2026, 5, 29), // 25 days
        ];

        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: starts,
          fallbackLength: 28,
        );

        expect(stats.cycleCount, equals(5));
        expect(stats.recentCycleLengths, equals([23, 34, 27, 39, 25]));
        expect(stats.minimumCycleLength, equals(23));
        expect(stats.maximumCycleLength, equals(39));
        expect(stats.medianCycleLength, equals(27.0));
        expect(stats.cycleVariability, greaterThan(6.0)); // > 6.0 std dev
        expect(
          stats.regularityClass,
          anyOf(
            equals(RegularityClass.variable),
            equals(RegularityClass.highlyVariable),
          ),
        );
      },
    );

    test(
      '5. Recent history has greater influence via weightedRecencyLength',
      () {
        // 3 older 28-day cycles, followed by 2 recent 32-day cycles
        final starts = [
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 29), // 28
          DateTime(2026, 2, 26), // 28
          DateTime(2026, 3, 26), // 28
          DateTime(2026, 4, 27), // 32
          DateTime(2026, 5, 29), // 32
        ];

        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: starts,
          fallbackLength: 28,
        );

        // Simple mean is 29.6, but weighted recency should skew closer to 32
        expect(
          stats.weightedRecencyLength,
          greaterThan(stats.meanCycleLength!),
        );
        expect(stats.weightedRecencyLength, greaterThan(30.0));
      },
    );
  });
}
