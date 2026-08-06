import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.wellnessBrown,
              size: 28.0,
            ),
          ),
          title: Text(
            'About',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mission Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.r24,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.wellnessBrown.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OUR MISSION',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.wellnessOrangeAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Empowering women to harmonize their fitness and wellness with their natural biology. Syd Flows provides cycle-aware insights to help you thrive in every phase of your journey.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h24,

              // 2. Dual cards side-by-side
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5EC), // Soft pink
                        borderRadius: AppRadius.r24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.wellnessPinkText,
                            size: 20.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Biologically\nDriven',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.wellnessBrown,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F2EB), // Soft beige
                        borderRadius: AppRadius.r24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.wellnessOrangeAccent,
                            size: 20.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Phase-Matched\nEnergy',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.wellnessBrown,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
