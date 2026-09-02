import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../cycle/presentation/screens/cycle_screen.dart';
import '../../../cycle/presentation/widgets/cycle_provider.dart';
import '../../../cycle/data/models/cycle_types.dart';
import '../../../workout/presentation/screens/workout_screen.dart';
import '../../../workout/presentation/screens/workout_detail_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/workout_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Success banner state
  bool _showSuccessBanner = false;
  String _successSymptom = 'Cramps';
  Timer? _bannerTimer;

  // Selected symptoms tracking
  final Set<String> _selectedSymptoms = {};

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      UserService.instance.sendWelcomeNotificationIfNeeded(
        user.uid,
        name: user.displayName,
      );
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _logSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
        // Show success banner
        _successSymptom = symptom;
        _showSuccessBanner = true;

        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 3), () {
          setState(() {
            _showSuccessBanner = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          extendBody: false,
          body: Stack(
            children: [
              // Active Tab Content
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildTodayTab(),
                      const CycleScreen(),
                      const WorkoutScreen(),
                      const ProgressScreen(),
                      const ProfileScreen(),
                    ],
                  ),
                ),
              ),

              // Top Success Banner ("Logged: Cramps")
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                top: _showSuccessBanner
                    ? MediaQuery.of(context).padding.top + 12.0
                    : -100.0,
                left: 16.0,
                right: 16.0,
                child: _buildSuccessBanner(),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // --- Success Banner Widget ---
  Widget _buildSuccessBanner() {
    return AppSuccessBanner(message: 'Logged: $_successSymptom');
  }

  Workout _getPhaseMatchedWorkout(CyclePhase phase, List<Workout> workouts) {
    if (workouts.isEmpty) {
      return const Workout(
        id: 'default_today_pick',
        title: 'Sunrise Flow Yoga',
        category: 'YOGA',
        duration: 22,
        difficulty: 'Gentle',
        type: 'Yoga',
        equipment: 'Mat',
        imagePath:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=600&auto=format&fit=crop',
        videoUrl: 'https://www.youtube.com/watch?v=inpok4MKVLM',
      );
    }

    final validWorkouts = workouts.where((w) => w.hasVideo).toList();
    final listToFilter = validWorkouts.isNotEmpty ? validWorkouts : workouts;

    List<Workout> matched = [];
    switch (phase) {
      case CyclePhase.menstrual:
        matched = listToFilter.where((w) {
          final cat = w.category.toLowerCase();
          return (cat.contains('yoga') || cat.contains('stretch')) &&
              !cat.contains('power') &&
              !cat.contains('hiit');
        }).toList();
        break;
      case CyclePhase.follicular:
        matched = listToFilter.where((w) {
          final cat = w.category.toLowerCase();
          return cat.contains('pilates') || cat.contains('sculpt');
        }).toList();
        break;
      case CyclePhase.ovulation:
        matched = listToFilter.where((w) {
          final cat = w.category.toLowerCase();
          return cat.contains('strength') ||
              cat.contains('hiit') ||
              cat.contains('power');
        }).toList();
        break;
      case CyclePhase.luteal:
        matched = listToFilter.where((w) {
          final cat = w.category.toLowerCase();
          return cat.contains('pilates') ||
              cat.contains('stretch') ||
              cat.contains('flow');
        }).toList();
        break;
      case CyclePhase.unknown:
        matched = listToFilter;
        break;
    }

    if (matched.isNotEmpty) {
      return matched.first;
    }
    return listToFilter.first;
  }

  // --- Tab 0: TODAY TAB ---
  Widget _buildTodayTab() {
    final user = AuthService.instance.currentUser;
    final cycleNotifier = CycleProvider.ofNullable(context);
    final currentPhase =
        cycleNotifier?.currentStatus.phase ?? CyclePhase.follicular;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('videos').snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final allWorkouts = docs
            .where((doc) => !doc.id.startsWith('_settings'))
            .map((doc) => Workout.fromFirestore(doc.data(), doc.id))
            .toList();

        final recommendedWorkout = _getPhaseMatchedWorkout(
          currentPhase,
          allWorkouts,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.l),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.h16,
                _buildHeader(),
                AppSpacing.h16,
                _buildCycleStatusCard(),
                AppSpacing.h24,
                _buildSymptomsSection(),
                AppSpacing.h24,
                _buildTodayPickSection(recommendedWorkout),
                AppSpacing.h24,
                _buildQuickActionsRow(recommendedWorkout),
                AppSpacing.h24,
                _buildThisWeekChartCard(),
                AppSpacing.h16,
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Header Greeting Helper ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // --- Header Widget ---
  Widget _buildHeader() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return _buildHeaderContent(name: 'User', photoUrl: null);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService.instance.getUserProfileStream(currentUser.uid),
      builder: (context, snapshot) {
        final docData = snapshot.data?.data();

        final rawName =
            docData?['displayName'] as String? ?? currentUser.displayName ?? '';
        final email = docData?['email'] as String? ?? currentUser.email ?? '';
        final photoUrl =
            docData?['photoURL'] as String? ?? currentUser.photoURL;

        final fullName = rawName.trim().isNotEmpty
            ? rawName.trim()
            : (email.isNotEmpty ? email.split('@').first : 'User');

        final displayName = fullName.contains(' ')
            ? fullName.split(' ').first
            : fullName;

        return _buildHeaderContent(name: displayName, photoUrl: photoUrl);
      },
    );
  }

  Widget _buildHeaderContent({
    required String name,
    required String? photoUrl,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 4;
            });
          },
          child: Row(
            children: [
              // User Real Avatar Logo
              ValueListenableBuilder<String?>(
                valueListenable:
                    LocalStorageService.instance.profileImageNotifier,
                builder: (context, localImagePath, _) {
                  final hasLocalFile =
                      localImagePath != null &&
                      localImagePath.isNotEmpty &&
                      File(localImagePath).existsSync();

                  ImageProvider? imageProvider;
                  if (hasLocalFile) {
                    imageProvider = FileImage(File(localImagePath));
                  } else if (photoUrl != null && photoUrl.isNotEmpty) {
                    if (photoUrl.startsWith('/') &&
                        File(photoUrl).existsSync()) {
                      imageProvider = FileImage(File(photoUrl));
                    } else {
                      imageProvider = NetworkImage(photoUrl);
                    }
                  }

                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      border: Border.all(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wellnessBrown.withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageProvider != null
                          ? Image(
                              image: imageProvider,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.wellnessPink.withValues(
                                      alpha: 0.3,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.wellnessBrown,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            )
                          : Container(
                              color: AppColors.wellnessPink.withValues(
                                alpha: 0.3,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.wellnessBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              AppSpacing.w16,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.wellnessGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    name,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notification bell with live unread badge count
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.notifications);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wellnessBrown.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StreamBuilder<int>(
              stream: AuthService.instance.currentUser != null
                  ? UserService.instance.getUnreadNotificationsCountStream(
                      AuthService.instance.currentUser!.uid,
                    )
                  : Stream.value(0),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.wellnessBrown,
                      size: 20,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.wellnessPinkText,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- Cycle Status Card ---
  Widget _buildCycleStatusCard() {
    // Read from CycleStateNotifier — the authoritative computed cycle state
    final cycleNotifier = CycleProvider.ofNullable(context);

    if (cycleNotifier == null) {
      return _buildCycleStatusCardContent(
        cycleDay: 1,
        phaseName: 'Follicular phase',
        headlineText: 'Rising energy — build and explore',
        daysUntilNext: 27,
      );
    }

    final status = cycleNotifier.currentStatus;
    final phase = status.phase;

    String phaseName;
    String headlineText;
    switch (phase) {
      case CyclePhase.menstrual:
        phaseName = 'Menstrual phase';
        headlineText = 'Rest & recharge — prioritize gentle movement';
        break;
      case CyclePhase.follicular:
        phaseName = 'Follicular phase';
        headlineText = 'Rising energy — build and explore';
        break;
      case CyclePhase.ovulation:
        phaseName = 'Ovulation phase';
        headlineText = 'Peak energy & focus — push your limits';
        break;
      case CyclePhase.luteal:
        phaseName = 'Luteal phase';
        headlineText = 'Steady strength — listen to your body';
        break;
      case CyclePhase.unknown:
        phaseName = 'Follicular phase';
        headlineText = 'Rising energy — build and explore';
        break;
    }

    return _buildCycleStatusCardContent(
      cycleDay: status.cycleDay,
      phaseName: phaseName,
      headlineText: headlineText,
      daysUntilNext: status.daysRemaining,
    );
  }

  Widget _buildCycleStatusCardContent({
    required int cycleDay,
    required String phaseName,
    required String headlineText,
    required int daysUntilNext,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.06),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.r24,
        child: Stack(
          children: [
            // Top-right decorative semi-transparent pink circle
            Positioned(
              top: -32,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.wellnessPinkCategory.withValues(
                    alpha: 0.50,
                  ), // Figma #F08AAE at 50% opacity
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'YOUR FLOW TODAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.wellnessPinkCategory,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  AppSpacing.h8,
                  Text(
                    headlineText,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      height: 1.25,
                    ),
                  ),
                  AppSpacing.h4,
                  Text(
                    'Rising energy • $daysUntilNext days until your next period',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.wellnessGray,
                    ),
                  ),
                  AppSpacing.h24,
                  // Circular Progress Ring matching Figma (220x220)
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom Paint Ring
                          Positioned.fill(
                            child: CustomPaint(
                              painter: const _CycleRingPainter(),
                            ),
                          ),
                          // Text elements inside
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CYCLE DAY',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.wellnessGray.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  fontSize: 11.0,
                                ),
                              ),
                              Text(
                                '$cycleDay',
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: AppColors.wellnessBrown,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 42.0,
                                  height: 1.1,
                                ),
                              ),
                              AppSpacing.h4,
                              Container(
                                height: 26.0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors
                                      .phaseBadgeBg, // #FBE6D2 matching Figma
                                  borderRadius: BorderRadius.circular(100.0),
                                ),
                                child: Text(
                                  phaseName,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.wellnessBrown,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Symptoms Logging Section ---
  Widget _buildSymptomsSection() {
    final symptoms = [
      {'name': 'Cramps', 'icon': Icons.airline_seat_flat_rounded},
      {'name': 'Bloating', 'icon': Icons.bubble_chart_rounded},
      {'name': 'Fatigue', 'icon': Icons.nights_stay_rounded},
      {'name': 'Headache', 'icon': Icons.face_retouching_natural_rounded},
      {'name': 'Backache', 'icon': Icons.accessibility_new_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'How are you feeling?',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Log all
                for (var s in symptoms) {
                  final name = s['name'] as String;
                  if (!_selectedSymptoms.contains(name)) {
                    _selectedSymptoms.add(name);
                  }
                }
                _logSymptom('Symptoms');
              },
              child: Text(
                'Log all',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.wellnessPinkCategory,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.h16,
        // Horizontal list
        SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: symptoms.length,
            itemBuilder: (context, index) {
              final symptom = symptoms[index];
              final name = symptom['name'] as String;
              final icon = symptom['icon'] as IconData;
              final isSelected = _selectedSymptoms.contains(name);

              return GestureDetector(
                onTap: () => _logSymptom(name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  margin: const EdgeInsets.only(right: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.wellnessSymptomBgSelected
                        : AppColors.white,
                    borderRadius: AppRadius.r16,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.wellnessBrown
                          : AppColors.wellnessBeige.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.wellnessBrown.withValues(alpha: 0.08)
                            : AppColors.wellnessBrown.withValues(alpha: 0.02),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.wellnessBrown, size: 24),
                      AppSpacing.h8,
                      Text(
                        name,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Today's Pick Section ---
  Widget _buildTodayPickSection(Workout workout) {
    final user = AuthService.instance.currentUser;
    final coverImage = workout.imagePath.isNotEmpty
        ? workout.imagePath
        : 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=600&auto=format&fit=crop';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's pick",
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Switch to Workouts tab
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Text(
                'See all',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.wellnessPinkCategory,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.h16,
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            );
          },
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: AppRadius.r24,
              boxShadow: [
                BoxShadow(
                  color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                  blurRadius: 18.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.r24,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: coverImage.startsWith('http')
                        ? Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.wellnessPeachAccent,
                                        AppColors.wellnessPinkCategory,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                          )
                        : Image.asset(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.wellnessPeachAccent,
                                        AppColors.wellnessPinkCategory,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.black.withValues(alpha: 0.0),
                            AppColors.black.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.wellnessSymptomBgSelected,
                        borderRadius: AppRadius.rCircular,
                      ),
                      child: Text(
                        'Matched to your phase',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.wellnessPinkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: StreamBuilder<bool>(
                      stream: user != null
                          ? WorkoutService.instance.streamIsFavorite(
                              user.uid,
                              workout.id,
                            )
                          : Stream.value(false),
                      builder: (context, favSnapshot) {
                        final isFav = favSnapshot.data ?? false;
                        return GestureDetector(
                          onTap: () async {
                            if (user == null) return;
                            final nowFav = await WorkoutService.instance
                                .toggleFavorite(
                                  uid: user.uid,
                                  workout: workout,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    nowFav
                                        ? 'Added to Favorites ❤️'
                                        : 'Removed from Favorites',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.wellnessBrown,
                                ),
                              );
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav
                                  ? AppColors.wellnessPinkText
                                  : AppColors.wellnessPinkCategory,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${workout.category} • ${workout.difficulty.toUpperCase()}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.h4,
                        Text(
                          workout.title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.h4,
                        Text(
                          '${workout.duration} min • ${workout.type}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Quick Actions Row ---
  Widget _buildQuickActionsRow(Workout recommendedWorkout) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            title: 'Continue',
            subtitle:
                '${recommendedWorkout.type} • ${recommendedWorkout.duration}m',
            icon: Icons.play_arrow_outlined,
            cardBg: AppColors.wellnessPinkCardBg,
            iconBg: AppColors.white,
            iconColor: AppColors.wellnessBrown,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WorkoutDetailScreen(workout: recommendedWorkout),
                ),
              );
            },
          ),
        ),
        AppSpacing.w8,
        Expanded(
          child: _buildQuickActionCard(
            title: 'Log period',
            subtitle: 'Tap to add',
            icon: Icons.water_drop_outlined,
            cardBg: AppColors.wellnessBeigeCardBg,
            iconBg: AppColors.white,
            iconColor: AppColors.wellnessBrown,
            onTap: () {
              setState(() {
                _currentIndex = 1; // Cycle tab
              });
            },
          ),
        ),
        AppSpacing.w8,
        Expanded(
          child: _buildQuickActionCard(
            title: 'Progress',
            subtitle: 'View trends',
            icon: Icons.trending_up_rounded,
            cardBg: AppColors.white,
            iconBg: AppColors.wellnessPinkBg,
            iconColor: AppColors.wellnessBrown,
            onTap: () {
              setState(() {
                _currentIndex = 3; // Progress tab
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBg,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 112,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: cardBg == AppColors.white
              ? [
                  BoxShadow(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.04),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.h4,
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.wellnessGray,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- This Week Session Chart Card ---
  Widget _buildThisWeekChartCard() {
    final user = AuthService.instance.currentUser;

    return StreamBuilder<List<CompletedWorkoutRecord>>(
      stream: user != null
          ? WorkoutService.instance.streamCurrentWeekWorkouts(user.uid)
          : Stream.value([]),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];

        // Daily minutes array for Mon (0) to Sun (6)
        final List<int> dayMinutes = List.filled(7, 0);
        int totalMinutes = 0;
        int completedSessions = records.length;

        for (final rec in records) {
          final weekdayIndex = rec.completedAt.weekday - 1;
          if (weekdayIndex >= 0 && weekdayIndex < 7) {
            dayMinutes[weekdayIndex] += rec.duration;
            totalMinutes += rec.duration;
          }
        }

        // Max daily minutes for scaling (minimum 45m target)
        int maxDailyMinutes = 45;
        for (final m in dayMinutes) {
          if (m > maxDailyMinutes) maxDailyMinutes = m;
        }

        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        final chartData = List.generate(7, (index) {
          final mins = dayMinutes[index];
          // Empty state (0 mins tracked): fraction is 0.0 => NO bar line
          final double fraction = mins > 0
              ? (mins / maxDailyMinutes).clamp(0.18, 1.0)
              : 0.0;

          return {
            'day': days[index],
            'val': fraction,
            'color':
                AppColors.wellnessPinkSaturday, // Unified solid theme color
          };
        });

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.r24,
            boxShadow: [
              BoxShadow(
                color: AppColors.wellnessBrown.withValues(alpha: 0.05),
                blurRadius: 15.0,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.wellnessBeige.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '$completedSessions of 5 sessions complete',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.wellnessGray,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalMinutes',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'MINUTES',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.wellnessGray,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.h24,
              SizedBox(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartData.map((data) {
                    final double fraction = data['val'] as double;
                    final String day = data['day'] as String;
                    final Color color = data['color'] as Color;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: fraction > 0.0
                              ? TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: fraction,
                                  ),
                                  builder: (context, value, child) {
                                    return FractionallySizedBox(
                                      heightFactor: value,
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 28,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        AppSpacing.h8,
                        Text(
                          day,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.wellnessGray,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Placeholder Screens for other tabs ---
}

// --- Custom Painter for Cycle Ring Progress ---
class _CycleRingPainter extends CustomPainter {
  const _CycleRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 14) / 2;
    const strokeWidth = 14.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Starting angle at top (12 o'clock)
    const double startAngle = -math.pi / 2;

    // Segment fractions (28 day cycle)
    const double menstrualFraction = 5.0 / 28.0; // Menstrual phase (#FE2C54)
    const double follicularFraction = 8.0 / 28.0; // Follicular phase (#FF94AF)
    const double ovulationFraction = 4.0 / 28.0; // Ovulation phase (#C291A4)
    const double lutealFraction = 11.0 / 28.0; // Luteal phase (#E75084)

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Ovulation Arc (#C291A4) - Bottom segment drawn first
    paint.color = AppColors.phaseOvulation;
    final double ovulationStart =
        startAngle + 2 * math.pi * (menstrualFraction + follicularFraction);
    final double ovulationSweep = 2 * math.pi * ovulationFraction;
    canvas.drawArc(rect, ovulationStart, ovulationSweep, false, paint);

    // 2. Luteal Arc (#E75084) - Left segment drawn second, overlapping Ovulation left end
    paint.color = AppColors.phaseLuteal;
    final double lutealStart = ovulationStart + ovulationSweep;
    final double lutealSweep = 2 * math.pi * lutealFraction;
    canvas.drawArc(rect, lutealStart, lutealSweep, false, paint);

    // 3. Follicular Arc (#FF94AF) - Right segment drawn third, overlapping Ovulation right end
    paint.color = AppColors.phaseFollicular;
    final double follicularStart = startAngle + 2 * math.pi * menstrualFraction;
    final double follicularSweep = 2 * math.pi * follicularFraction;
    canvas.drawArc(rect, follicularStart, follicularSweep, false, paint);

    // 4. Menstrual Arc (#FE2C54) - Top segment drawn fourth, overlapping top ends
    paint.color = AppColors.phaseMenstrual;
    final double menstrualStart = startAngle;
    final double menstrualSweep = 2 * math.pi * menstrualFraction;
    canvas.drawArc(rect, menstrualStart, menstrualSweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) => false;
}
