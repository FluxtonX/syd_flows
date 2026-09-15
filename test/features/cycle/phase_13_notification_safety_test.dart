import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/notification_safety_evaluator.dart';

void main() {
  group('Phase 13 — Notification Safety Engine', () {
    final DateTime baseDate = DateTime(2026, 9, 1);
    final CycleSettings defaultSettings = CycleSettings(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodLength: 5,
    );

    final List<DateTime> regularStarts = [
      baseDate.subtract(const Duration(days: 84)),
      baseDate.subtract(const Duration(days: 56)),
      baseDate.subtract(const Duration(days: 28)),
      baseDate,
    ];

    test('Allows notification when confidence is high and event not recorded', () {
      final stats = CycleCalculator.computeStatistics(
        confirmedStarts: regularStarts,
        fallbackLength: 28,
      );

      final status = CycleCalculator.compute(
        settings: defaultSettings,
        today: baseDate.add(const Duration(days: 20)),
        stats: stats,
      );

      final decision = NotificationSafetyEvaluator.evaluatePeriodReminder(
        status: status,
        targetNotificationDate: baseDate.add(const Duration(days: 28)),
        isEventAlreadyRecorded: false,
      );

      expect(decision.shouldTrigger, isTrue);
    });

    test('Suppresses notification when event is already recorded', () {
      final status = CycleCalculator.compute(
        settings: defaultSettings,
        today: baseDate.add(const Duration(days: 20)),
      );

      final decision = NotificationSafetyEvaluator.evaluatePeriodReminder(
        status: status,
        targetNotificationDate: baseDate.add(const Duration(days: 28)),
        isEventAlreadyRecorded: true,
      );

      expect(decision.shouldTrigger, isFalse);
      expect(decision.reason, contains('already been recorded'));
    });

    test('Suppresses notification when cycle is severely overdue (>7 days)', () {
      final status = CycleCalculator.compute(
        settings: defaultSettings,
        today: baseDate.add(const Duration(days: 38)), // 10 days late
      );

      final decision = NotificationSafetyEvaluator.evaluatePeriodReminder(
        status: status,
        targetNotificationDate: baseDate.add(const Duration(days: 38)),
        isEventAlreadyRecorded: false,
      );

      expect(decision.shouldTrigger, isFalse);
    });
  });
}
