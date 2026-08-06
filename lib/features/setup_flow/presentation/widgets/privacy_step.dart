import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrivacyStep extends StatelessWidget {
  const PrivacyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.r24,
        border: Border.all(
          color: AppColors.wellnessBeige.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Security icon at the top
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 54.0,
              height: 54.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.wellnessSalmon.withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.wellnessPinkCategory,
                size: 26.0,
              ),
            ),
          ),
          AppSpacing.h24,

          // Title
          Text(
            'Your data is yours',
            textAlign: TextAlign.left,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.h16,

          // Description
          Text(
            'Cycle and symptom data is encrypted on your device and never sold. You can export or delete it any time from Settings.',
            textAlign: TextAlign.left,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              height: 1.45,
            ),
          ),
          AppSpacing.h24,

          // Bullets
          _buildBulletItem('End-to-end encryption'),
          AppSpacing.h8,
          _buildBulletItem('No third-party tracking'),
          AppSpacing.h8,
          _buildBulletItem('Export anytime as CSV'),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.wellnessBrown,
            size: 16.0,
          ),
        ),
        AppSpacing.w8,
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
