import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedGradientTheme {
  AnimatedGradientTheme._();

  // Configurations for animated gradient backgrounds
  static const List<Color> lightGradients = [
    Color(0xFFEEF2F6),
    Color(0xFFE0E7FF),
    Color(0xFFFCE7F3),
  ];

  static const List<Color> darkGradients = AppColors.backgroundGradient;

  static const double minBlurRadius = 40.0;
  static const double maxBlurRadius = 120.0;

  static const double defaultOpacityLight = 0.6;
  static const double defaultOpacityDark = 0.2;
}
