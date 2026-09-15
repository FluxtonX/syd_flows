import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/workout_recommendation_engine.dart';

void main() {
  group('Phase 12 — Personalized Workout Recommendation Engine', () {
    test('Low energy or cramps during menstrual phase suggests gentle mode', () {
      final rec = WorkoutRecommendationEngine.recommend(
        phase: CyclePhase.menstrual,
        energy: 1.5,
        symptoms: ['cramps', 'fatigue'],
        flow: 'heavy',
      );

      expect(rec.intensity, equals(WorkoutIntensity.gentle));
      expect(rec.isGentleModeSuggested, isTrue);
      expect(rec.recommendedTypes, contains('Yin Yoga'));
    });

    test('High energy during menstrual phase allows moderate pilates/sculpt', () {
      final rec = WorkoutRecommendationEngine.recommend(
        phase: CyclePhase.menstrual,
        energy: 4.5,
        symptoms: [],
        flow: 'light',
      );

      expect(rec.intensity, equals(WorkoutIntensity.moderate));
      expect(rec.isGentleModeSuggested, isFalse);
    });

    test('High energy during follicular phase recommends active strength/cardio', () {
      final rec = WorkoutRecommendationEngine.recommend(
        phase: CyclePhase.follicular,
        energy: 4.0,
      );

      expect(rec.intensity, equals(WorkoutIntensity.active));
      expect(rec.suggestedCategory, equals('Strength & Cardio'));
    });

    test('High energy during ovulation phase recommends peak HIIT/power sculpt', () {
      final rec = WorkoutRecommendationEngine.recommend(
        phase: CyclePhase.ovulation,
        energy: 4.5,
      );

      expect(rec.intensity, equals(WorkoutIntensity.peak));
      expect(rec.recommendedTypes, contains('HIIT'));
    });
  });
}
