import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // Core double radius values
  static const double s = 4.0;
  static const double m = 8.0;
  static const double l = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double circular = 999.0;

  // Reusable BorderRadius objects
  static const BorderRadius r4 = BorderRadius.all(Radius.circular(s));
  static const BorderRadius r8 = BorderRadius.all(Radius.circular(m));
  static const BorderRadius r12 = BorderRadius.all(Radius.circular(l));
  static const BorderRadius r16 = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius r24 = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rCircular = BorderRadius.all(Radius.circular(circular));
}
