import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SliderSelectionStep extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unitText;
  final Gradient? cardGradient;
  final Color? cardColor;
  final Color? inactiveTrackColor;

  const SliderSelectionStep({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unitText,
    this.cardGradient,
    this.cardColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardGradient == null ? (cardColor ?? const Color(0xFFFBF7F2)) : null,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24.0), // Figma corner radius: 24
        border: Border.all(
          color: const Color(0xFF4B2E16), // Figma stroke: #4B2E16
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B2E16).withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display the big number and unit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toString(),
                style: AppTextStyles.displayLarge.copyWith(
                  color: const Color(0xFF4B2E16), // Figma text #4B2E16
                  fontSize: 72.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              AppSpacing.w12,
              Text(
                unitText,
                style: AppTextStyles.titleLarge.copyWith(
                  color: const Color(0xFF7A5638), // Figma unit text #7A5638
                  fontWeight: FontWeight.w600,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36.0),

          // Custom styled Slider matching Figma
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 16.0,
              activeTrackColor: const Color(0xFF4B2E16), // Figma #4B2E16
              inactiveTrackColor: inactiveTrackColor ?? const Color(0xFFF6EFE6), // Figma #F6EFE6
              overlayColor: const Color(0xFF4B2E16).withValues(alpha: 0.08),
              thumbShape: const _BorderedSliderThumbShape(
                enabledThumbRadius: 11.0,
                fillColor: Color(0xFFFBF7F2), // Figma #FBF7F2
                borderColor: Color(0xFF4B2E16),
                borderWidth: 1.8,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 20.0,
              ),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BorderedSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  const _BorderedSliderThumbShape({
    this.enabledThumbRadius = 11.0,
    this.fillColor = const Color(0xFFFBF7F2),
    this.borderColor = const Color(0xFF4B2E16),
    this.borderWidth = 1.8,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, enabledThumbRadius, fillPaint);
    canvas.drawCircle(center, enabledThumbRadius, borderPaint);
  }
}
