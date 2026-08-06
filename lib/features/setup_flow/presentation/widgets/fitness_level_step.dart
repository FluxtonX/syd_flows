import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FitnessOption {
  final String title;
  final String subtitle;

  const FitnessOption({
    required this.title,
    required this.subtitle,
  });
}

class FitnessLevelStep extends StatelessWidget {
  final String? selectedLevel;
  final ValueChanged<String> onLevelSelected;

  const FitnessLevelStep({
    super.key,
    this.selectedLevel,
    required this.onLevelSelected,
  });

  static const List<FitnessOption> options = [
    FitnessOption(
      title: 'Excited to start moving',
      subtitle: 'Just getting started',
    ),
    FitnessOption(
      title: 'I like to dabble',
      subtitle: '1–2 sessions per week',
    ),
    FitnessOption(
      title: 'Movement on my mind',
      subtitle: '3–4 sessions per week',
    ),
    FitnessOption(
      title: 'Lover of movement',
      subtitle: '5+ sessions per week',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        final isActive = option.title == selectedLevel;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.r16,
              border: Border.all(
                color: isActive
                    ? AppColors.wellnessPinkCategory
                    : AppColors.transparent,
                width: 2.0,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: AppColors.wellnessPinkCategory.withValues(alpha: 0.25),
                    blurRadius: 10.0,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.02),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: InkWell(
              onTap: () => onLevelSelected(option.title),
              borderRadius: AppRadius.r16,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      option.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.h4,
                    Text(
                      option.subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
