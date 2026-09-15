import '../data/models/cycle_types.dart';

/// Workout intensity recommendation classification (Phase 12).
enum WorkoutIntensity {
  gentle,
  moderate,
  active,
  peak;

  String get label {
    switch (this) {
      case WorkoutIntensity.gentle:
        return 'Gentle';
      case WorkoutIntensity.moderate:
        return 'Moderate';
      case WorkoutIntensity.active:
        return 'Active';
      case WorkoutIntensity.peak:
        return 'Peak';
    }
  }
}

/// Value object representing a personalized workout recommendation (Phase 12).
class WorkoutRecommendation {
  final WorkoutIntensity intensity;
  final String suggestedCategory;
  final List<String> recommendedTypes;
  final String guidanceText;
  final bool isGentleModeSuggested;

  const WorkoutRecommendation({
    required this.intensity,
    required this.suggestedCategory,
    required this.recommendedTypes,
    required this.guidanceText,
    required this.isGentleModeSuggested,
  });
}

/// Pure domain service for evidence-aware workout recommendations (Phase 12 Engine).
///
/// Combines estimated cycle phase, energy level, symptoms, and flow.
/// Never claims a workout is medically mandatory or dictated by hormonal phases alone.
class WorkoutRecommendationEngine {
  const WorkoutRecommendationEngine._();

  static WorkoutRecommendation recommend({
    required CyclePhase phase,
    double energy = 3.0,
    List<String> symptoms = const [],
    String? flow,
    DayJournal? journal,
  }) {
    final double actualEnergy = journal?.energy ?? energy;
    final List<String> actualSymptoms = journal?.symptoms ?? symptoms;
    final String? actualFlow = journal?.flow ?? flow;

    final bool hasHeavyFlow = actualFlow == 'heavy';
    final bool hasHighDiscomfort = actualSymptoms.any(
      (s) => s.toLowerCase().contains('cramp') ||
          s.toLowerCase().contains('pain') ||
          s.toLowerCase().contains('fatigue') ||
          s.toLowerCase().contains('migraine') ||
          s.toLowerCase().contains('headache'),
    );

    // 1. High discomfort or very low energy triggers Gentle Mode
    if (actualEnergy <= 2.0 || hasHeavyFlow || hasHighDiscomfort) {
      return const WorkoutRecommendation(
        intensity: WorkoutIntensity.gentle,
        suggestedCategory: 'Yoga & Mobility',
        recommendedTypes: ['Yin Yoga', 'Restorative Stretch', 'Light Breathing'],
        guidanceText: 'Gentle mobility or restorative stretch is suggested based on reported comfort and energy.',
        isGentleModeSuggested: true,
      );
    }

    // 2. Phase-based recommendations balanced with user energy
    switch (phase) {
      case CyclePhase.menstrual:
        if (actualEnergy >= 4.0) {
          return const WorkoutRecommendation(
            intensity: WorkoutIntensity.moderate,
            suggestedCategory: 'Pilates & Light Strength',
            recommendedTypes: ['Mat Pilates', 'Bodyweight Sculpt', 'Flow Yoga'],
            guidanceText: 'Your energy feels strong. Moderate Pilates or light sculpt aligns well today.',
            isGentleModeSuggested: false,
          );
        }
        return const WorkoutRecommendation(
          intensity: WorkoutIntensity.gentle,
          suggestedCategory: 'Gentle Flow',
          recommendedTypes: ['Gentle Yoga', 'Pelvic Floor Stretch', 'Walking'],
          guidanceText: 'Gentle movement and low-impact stretch support body comfort today.',
          isGentleModeSuggested: true,
        );

      case CyclePhase.follicular:
        if (actualEnergy >= 3.5) {
          return const WorkoutRecommendation(
            intensity: WorkoutIntensity.active,
            suggestedCategory: 'Strength & Cardio',
            recommendedTypes: ['Full Body Strength', 'Dance Cardio', 'Dynamic Pilates'],
            guidanceText: 'Rising energy makes this a great time for active strength or dynamic cardio.',
            isGentleModeSuggested: false,
          );
        }
        return const WorkoutRecommendation(
          intensity: WorkoutIntensity.moderate,
          suggestedCategory: 'Core & Mobility',
          recommendedTypes: ['Core Sculpt', 'Mobility Flow', 'Low Impact Cardio'],
          guidanceText: 'Balanced core sculpt or mobility flow matches your current energy.',
          isGentleModeSuggested: false,
        );

      case CyclePhase.ovulation:
        if (actualEnergy >= 4.0) {
          return const WorkoutRecommendation(
            intensity: WorkoutIntensity.peak,
            suggestedCategory: 'HIIT & Peak Conditioning',
            recommendedTypes: ['HIIT', 'Power Pilates', 'Interval Strength'],
            guidanceText: 'High energy capacity today supports peak intensity intervals or power sculpt.',
            isGentleModeSuggested: false,
          );
        }
        return const WorkoutRecommendation(
          intensity: WorkoutIntensity.active,
          suggestedCategory: 'Sculpt & Barre',
          recommendedTypes: ['Power Sculpt', 'Barre', 'Cardio Flow'],
          guidanceText: 'Active sculpt or barre provides an energizing session today.',
          isGentleModeSuggested: false,
        );

      case CyclePhase.luteal:
      case CyclePhase.unknown:
        if (actualEnergy >= 3.5) {
          return const WorkoutRecommendation(
            intensity: WorkoutIntensity.moderate,
            suggestedCategory: 'Strength & Steady State',
            recommendedTypes: ['Targeted Strength', 'Mat Pilates', 'Steady Cardio'],
            guidanceText: 'Steady-state strength or targeted Pilates provides a solid workout.',
            isGentleModeSuggested: false,
          );
        }
        return const WorkoutRecommendation(
          intensity: WorkoutIntensity.gentle,
          suggestedCategory: 'Stretch & Balance',
          recommendedTypes: ['Slow Flow Yoga', 'Postural Stretch', 'Mindful Walking'],
          guidanceText: 'Slow flow yoga or mindful walking helps sustain steady energy.',
          isGentleModeSuggested: true,
        );
    }
  }
}
