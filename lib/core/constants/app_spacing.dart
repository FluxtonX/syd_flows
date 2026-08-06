import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Core padding and margin values
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double sm = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Reusable width spacers
  static const SizedBox w4 = SizedBox(width: xs);
  static const SizedBox w8 = SizedBox(width: s);
  static const SizedBox w12 = SizedBox(width: sm);
  static const SizedBox w16 = SizedBox(width: m);
  static const SizedBox w24 = SizedBox(width: l);
  static const SizedBox w32 = SizedBox(width: xl);

  // Reusable height spacers
  static const SizedBox h4 = SizedBox(height: xs);
  static const SizedBox h8 = SizedBox(height: s);
  static const SizedBox h12 = SizedBox(height: sm);
  static const SizedBox h16 = SizedBox(height: m);
  static const SizedBox h24 = SizedBox(height: l);
  static const SizedBox h32 = SizedBox(height: xl);
  static const SizedBox h48 = SizedBox(height: xxl);
}
