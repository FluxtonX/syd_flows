class AppAssets {
  AppAssets._();

  // Fonts
  static const String primaryFont = 'Outfit'; // Centralized typography font

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _illustrationsPath = 'assets/illustrations';
  static const String _lottiePath = 'assets/lottie';

  // Images
  static const String logo = '$_imagesPath/Logo.png';
  static const String splashBackground = '$_imagesPath/splash_bg.png';
  static const String googleLogo = '$_imagesPath/google/Google.png';

  // Workout Images
  static const String _workoutPath = '$_imagesPath/workout';
  static const String sunriseFlow = '$_workoutPath/sunrise_flow.png';
  static const String pilatesCore = '$_workoutPath/pilates_core.png';
  static const String powerStrength = '$_workoutPath/power_strength.png';
  static const String restorativeStretch = '$_workoutPath/restorative_stretch.png';
  static const String barreSculpt = '$_workoutPath/barre_sculpt.png';
  static const String breathOutdoor = '$_workoutPath/breath_outdoor.png';

  // Bottom Navigation Icons
  static const String _navIconsPath = '$_iconsPath/buttomNavIcons';
  static const String navToday = '$_navIconsPath/today.svg';
  static const String navCycle = '$_navIconsPath/cycle.svg';
  static const String navWorkouts = '$_navIconsPath/workouts.svg';
  static const String navProgress = '$_navIconsPath/progress.svg';
  static const String navProfile = '$_navIconsPath/profile.svg';

  // Subscription & Profile Icons
  static const String premiumBadge = 'assets/icons/subscription/permium.svg';
  static const String profileAchievements = 'assets/icons/profile/achievements.svg';
  static const String profilePremium = 'assets/icons/profile/premium.svg';

  // Icons
  static const String homeIcon = '$_iconsPath/ic_home.png';
  static const String cycleIcon = '$_iconsPath/ic_cycle.png';
  static const String workoutIcon = '$_iconsPath/ic_workout.png';
  static const String progressIcon = '$_iconsPath/ic_progress.png';
  static const String profileIcon = '$_iconsPath/ic_profile.png';

  // Illustrations
  static const String onboardingStart = '$_illustrationsPath/onboarding_start.png';

  // Animations & Lottie
  static const String loadingAnimation = '$_lottiePath/loading.json';
}
