import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class EquipmentStep extends StatelessWidget {
  final List<String> selectedEquipment;
  final ValueChanged<String> onEquipmentToggled;

  const EquipmentStep({
    super.key,
    required this.selectedEquipment,
    required this.onEquipmentToggled,
  });

  static const List<String> equipmentList = [
    'Mat',
    'Light Dumbbells',
    'Heavy Dumbbells',
    'Open Ended Band',
    'Pillow',
    'Ankle Weights',
    'Pilates Circle',
    'Yoga Blocks',
    'Foam Roller',
    'Booty Bands',
    'Pilates Ball',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: equipmentList.map((item) {
            final isSelected = selectedEquipment.contains(item);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onEquipmentToggled(item),
                borderRadius: AppRadius.r8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.wellnessBrown : AppColors.white,
                    borderRadius: AppRadius.r8,
                    border: Border.all(
                      color: isSelected ? AppColors.wellnessBrown : Colors.transparent,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.wellnessBrown.withValues(alpha: 0.2)
                            : AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.wellnessBrown,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 15.0,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8.0),
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 16.0,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
