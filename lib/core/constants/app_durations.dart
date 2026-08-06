class AppDurations {
  AppDurations._();

  // Animation and interaction durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  // Feature specific durations
  static const Duration splashDelay = Duration(seconds: 2);
  static const Duration pageTransition = Duration(milliseconds: 300);
}
