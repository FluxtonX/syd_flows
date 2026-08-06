import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFF6366F1);      // Indigo/Purple vibe
  static const Color secondary = Color(0xFFEC4899);    // Pink/Coral vibe
  static const Color accent = Color(0xFF14B8A6);       // Emerald/Teal vibe

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Theme Colors (Sleek Dark Mode)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);

  // Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradient definitions (For background and highlights)
  static const List<Color> backgroundGradient = [
    Color(0xFF090D16),
    Color(0xFF111827),
    Color(0xFF1E1E38),
  ];

  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
  ];

  // Wellness Warm Theme Colors (For Splash/Onboarding)
  // Matches Figma design exactly
  static const Color wellnessCream = Color(0xFFFBF7F2); // Light cream mid-tone
  static const Color wellnessPink = Color(0xFFFFB3D0);  // Soft pink
  static const Color wellnessBrown = Color(0xFF4B2E16); // Dark brown (text)
  static const Color wellnessBeige = Color(0xFF7A5638); // Medium brown (dots/inactive)
  static const Color wellnessGray = Color(0xFF7F7166);  // Muted gray-brown (subtitle)
  static const Color wellnessSalmon = Color(0xFFF0BAAE); // Salmon accent

  // 3-stop gradient from Figma: peach → cream → pink
  static const List<Color> wellnessGradient = [
    Color(0xFFEEC9A4), // 0%   – Warm peach/golden
    Color(0xFFFBF7F2), // 50%  – Light cream
    Color(0xFFFFB3D0), // 100% – Soft pink
  ];

  // Standard Color Helpers
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Wellness Warm Theme Additional Colors
  static const Color successGreenBg = Color(0xFF032213);
  static const Color wellnessOrangeBg = Color(0xFFFEF4E9);
  static const Color wellnessOrangeText = Color(0xFFD67323);
  static const Color wellnessPinkBg = Color(0xFFFCDDEC);
  static const Color wellnessPinkAccent = Color(0xFFEE8AA4);
  static const Color wellnessOrangeAccent = Color(0xFFF5B075);
  static const Color wellnessGrayAccent = Color(0xFF9E8E81);
  static const Color wellnessSymptomBgSelected = Color(0xFFFDE8E8);
  static const Color wellnessPinkText = Color(0xFFC75D85);
  static const Color wellnessPinkCardBg = Color(0xFFFDE8F1);
  static const Color wellnessBeigeCardBg = Color(0xFFF6ECE1);
  static const Color wellnessPinkSaturday = Color(0xFFE380A5);
  static const Color wellnessPinkCategory = Color(0xFFF08AAE);
  static const Color wellnessPeachAccent = Color(0xFFEAA584);
  static const Color wellnessPinkLightBg = Color(0xFFFFF0F5);
  static const Color wellnessPinkBorder = Color(0xFFF5B5CD);
  // System Notification Colors
  static const Color systemNotificationBg = Color(0xFFEEF2F6);
  static const Color systemNotificationIcon = Color(0xFF64748B);

  // Cycle Phase Colors matching Figma exactly
  static const Color phaseMenstrual = Color(0xFFFE2C54);  // Coral Red/Pink (#FE2C54 matching Figma)
  static const Color phaseFollicular = Color(0xFFFF94AF); // Soft Pink (#FF94AF matching Figma)
  static const Color phaseLuteal = Color(0xFFE75084);     // Vibrant Rose/Magenta
  static const Color phaseOvulation = Color(0xFFC291A4);  // Muted Mauve (#C291A4 matching Figma)
  static const Color phaseBadgeBg = Color(0xFFFBE6D2);    // Phase Pill Background (#FBE6D2 matching Figma)

  // Gradient for "Log today" action button matching exact Figma properties
  static const List<Color> logTodayGradient = [
    Color(0xFFFFE1EC), // Top stop (#FFE1EC matching Figma)
    Color(0xFFFFB7CE), // Bottom stop (#FFB7CE matching Figma)
  ];

  // Setup Flow Card Gradients matching Figma properties
  static const Color cycleLengthGradientTop = Color(0xFFF5E6D3);
  static const Color cycleLengthGradientBottom = Color(0xFFFBF7F2);
  static const Color periodLengthGradientTop = Color(0xFFF08AAE);
  static const Color periodLengthGradientBottom = Color(0xFFFFE1EC);
}
