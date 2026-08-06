import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textStyle = AppTextStyles.labelLarge.copyWith(
      color: isSecondary
          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
          : Colors.white,
    );

    return SizedBox(
      height: AppSizes.buttonHeightLarge,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? (isDark ? AppColors.darkCard : AppColors.lightCard)
              : AppColors.primary,
          foregroundColor: isSecondary
              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
              : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.r16,
          ),
          elevation: AppSizes.cardElevation,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: textStyle,
              ),
      ),
    );
  }
}
