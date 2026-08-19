import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';
import 'workout_screen.dart';
import 'workout_player_screen.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/workout_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../profile/presentation/screens/subscription_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isSaved = false;
  bool _isLiked = false;
  bool _showSuccessBanner = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

  final Map<String, Map<String, dynamic>> _details = {
    '1': {
      'category': 'YOGA',
      'instructor': 'WITH MAYA LINDEN',
      'about':
          'A slow, breath-led flow designed to ease tension and gently wake the body. Perfect for low-energy mornings.',
      'benefits': [
        'Improves flexibility',
        'Calms the nervous system',
        'Boosts circulation',
      ],
      'phases': [
        {'name': 'Follicular', 'bg': Color(0xFFFFD8B3)},
        {'name': 'Luteal', 'bg': Color(0xFFF3D5E4)},
      ],
      'symptoms': ['Bloating', 'Low mood', 'Fatigue'],
      'equipment': ['Mat'],
    },
    '2': {
      'category': 'PILATES',
      'instructor': 'WITH EMILY WATSON',
      'about':
          'A focused core session designed to build stability, alignment, and strength. Ideal for high-energy days.',
      'benefits': ['Strengthens core', 'Improves posture', 'Enhances balance'],
      'phases': [
        {'name': 'Follicular', 'bg': Color(0xFFFFD8B3)},
        {'name': 'Ovulation', 'bg': Color(0xFFE8D4F0)},
      ],
      'symptoms': ['Cramps', 'Fatigue'],
      'equipment': ['Mat'],
    },
    '3': {
      'category': 'STRENGTH',
      'instructor': 'WITH MARCUS CHEN',
      'about':
          'A high-intensity strength circuit targeting major muscle groups. Great for maximum fat burn and power building.',
      'benefits': [
        'Increases power',
        'Boosts metabolism',
        'Builds lean muscle',
      ],
      'phases': [
        {'name': 'Follicular', 'bg': Color(0xFFFFD8B3)},
        {'name': 'Ovulation', 'bg': Color(0xFFE8D4F0)},
      ],
      'symptoms': ['Low mood'],
      'equipment': ['Dumbbells', 'Mat'],
    },
    '4': {
      'category': 'MOBILITY',
      'instructor': 'WITH SARAH JENKINS',
      'about':
          'Gentle stretching and mobility drills to release tight muscles and open joints. Perfect recovery session.',
      'benefits': ['Relieves tension', 'Enhances mobility', 'Reduces soreness'],
      'phases': [
        {'name': 'Luteal', 'bg': Color(0xFFF3D5E4)},
        {'name': 'Menstrual', 'bg': Color(0xFFFFC6C6)},
      ],
      'symptoms': ['Bloating', 'Headache', 'Cramps'],
      'equipment': ['Mat'],
    },
    '5': {
      'category': 'BARRE',
      'instructor': 'WITH ALYSIA SHARP',
      'about':
          'A low-impact, high-repetition workout utilizing ballet bar elements to sculpt and tone muscles.',
      'benefits': [
        'Tones legs & glutes',
        'Low impact',
        'Improves coordination',
      ],
      'phases': [
        {'name': 'Follicular', 'bg': Color(0xFFFFD8B3)},
        {'name': 'Luteal', 'bg': Color(0xFFF3D5E4)},
      ],
      'symptoms': ['Fatigue', 'Bloating'],
      'equipment': ['Chair'],
    },
    '6': {
      'category': 'CARDIO',
      'instructor': 'WITH DANIEL KRAUS',
      'about':
          'An outdoor cardio and breathing routine to oxygenate the body and boost mental clarity.',
      'benefits': ['Improves stamina', 'Boosts mood', 'Fresh air integration'],
      'phases': [
        {'name': 'Follicular', 'bg': Color(0xFFFFD8B3)},
        {'name': 'Ovulation', 'bg': Color(0xFFE8D4F0)},
      ],
      'symptoms': ['Anxious', 'Low mood'],
      'equipment': ['None'],
    },
  };

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _triggerSuccessBanner(String message) {
    setState(() {
      _bannerMessage = message;
      _showSuccessBanner = true;
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _showSuccessBanner = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _details[widget.workout.id] ?? _details['1']!;

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
          body: Stack(
            children: [
              // Scrollable Content
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Cover Image with Play Button overlay
                      _buildCoverImage(),

                      // 2. Overlapping Detail Card
                      _buildOverlappingDetailCard(detail),

                      // 3. Detail Content Sections
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSpacing.h16,

                            // About Section
                            _buildSectionTitle('About'),
                            const SizedBox(height: 8.0),
                            Text(
                              detail['about'],
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.wellnessBrown.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                            AppSpacing.h24,

                            // Benefits Section
                            _buildSectionTitle('Benefits'),
                            const SizedBox(height: 12.0),
                            ...List.generate(
                              (detail['benefits'] as List).length,
                              (index) => _buildBenefitCheckItem(
                                detail['benefits'][index],
                              ),
                            ),
                            AppSpacing.h24,

                            // Recommended phases Section
                            _buildSectionTitle('Recommended phases'),
                            const SizedBox(height: 10.0),
                            _buildPhaseChips((detail['phases'] as List?) ?? []),
                            AppSpacing.h24,

                            // Symptom-friendly Section
                            _buildSectionTitle('Symptom-friendly'),
                            const SizedBox(height: 10.0),
                            _buildSymptomChips(
                              (detail['symptoms'] as List?) ?? [],
                            ),
                            AppSpacing.h24,

                            // You'll need Section
                            _buildSectionTitle('You\'ll need'),
                            const SizedBox(height: 10.0),
                            _buildEquipmentChips(
                              (detail['equipment'] as List?) ?? [],
                            ),
                            AppSpacing.h24,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Floating Header Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 12.0,
                left: AppSpacing.l,
                right: AppSpacing.l,
                child: _buildHeaderBar(),
              ),

              // Offline Saved Banner
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                top: _showSuccessBanner
                    ? MediaQuery.of(context).padding.top + 72.0
                    : -100.0,
                left: 16.0,
                right: 16.0,
                child: Center(child: AppSuccessBanner(message: _bannerMessage)),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 2,
            onTap: (index) {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    String coverUrl = widget.workout.imagePath;
    if (coverUrl.isEmpty &&
        widget.workout.videoId != null &&
        widget.workout.videoId!.isNotEmpty) {
      coverUrl =
          'https://img.youtube.com/vi/${widget.workout.videoId}/hqdefault.jpg';
    }

    final isNetwork =
        coverUrl.startsWith('http://') || coverUrl.startsWith('https://');

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Cover Image
          Positioned.fill(
            child: isNetwork
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                : (coverUrl.isNotEmpty
                      ? Image.asset(
                          coverUrl,
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
                      : Container(
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
                        )),
          ),
          // Dark Gradient Overlay for play button readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          // A premium item may be browsed, but playback requires an entitlement.
          Center(
            child: StreamBuilder<bool>(
              stream: SubscriptionService.instance.streamHasPremiumAccess(),
              builder: (context, snapshot) {
                final isLocked = widget.workout.isPaid && snapshot.data != true;
                return GestureDetector(
                  onTap: () {
                    if (!widget.workout.hasVideo) {
                      _triggerSuccessBanner('No video available for this workout');
                      return;
                    }
                    if (isLocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutPlayerScreen(workout: widget.workout),
                      ),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : (widget.workout.hasVideo
                              ? Icons.play_arrow_rounded
                              : Icons.videocam_off_rounded),
                      color: AppColors.wellnessBrown,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Chevron button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.wellnessBrown,
              size: 26,
            ),
          ),
        ),
        // Action Buttons (Download, Favorite)
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSaved = !_isSaved;
                });
                _triggerSuccessBanner(
                  _isSaved ? 'Saved offline' : 'Removed from offline',
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  _isSaved
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                  color: _isSaved
                      ? AppColors.wellnessPinkText
                      : AppColors.wellnessBrown,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            StreamBuilder<bool>(
              stream: () {
                final uid = AuthService.instance.currentUser?.uid ?? '';
                return uid.isNotEmpty
                    ? WorkoutService.instance.streamIsFavorite(
                        uid,
                        widget.workout.id,
                      )
                    : Stream.value(false);
              }(),
              builder: (context, favSnapshot) {
                final isFav = favSnapshot.data ?? _isLiked;
                return GestureDetector(
                  onTap: () async {
                    final uid = AuthService.instance.currentUser?.uid ?? '';
                    if (uid.isEmpty) return;
                    final nowFav = await WorkoutService.instance.toggleFavorite(
                      uid: uid,
                      workout: widget.workout,
                    );
                    setState(() {
                      _isLiked = nowFav;
                    });
                    _triggerSuccessBanner(
                      nowFav
                          ? 'Added to Favorites ❤️'
                          : 'Removed from Favorites',
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? AppColors.wellnessPinkText
                          : AppColors.wellnessBrown,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlappingDetailCard(Map<String, dynamic> detail) {
    return Container(
      transform: Matrix4.translationValues(0.0, -32.0, 0.0),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Label
          Text(
            (detail['category'] ?? widget.workout.category).toString().toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFFEE8AA4),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8.0),

          // Workout Title
          Text(
            widget.workout.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
              fontSize: 26.0,
            ),
          ),
          const SizedBox(height: 16.0),

          // Duration Card (Full Width Single Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF7EFE9),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.wellnessBrown,
                  size: 20.0,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${widget.workout.duration}m',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'DURATION',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF8C7B70),
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.wellnessBrown,
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
      ),
    );
  }

  Widget _buildBenefitCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFF08AAE),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChips(List<dynamic> phases) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: phases.map((phaseItem) {
        String phaseName = '';
        Color phaseBg = const Color(0xFFFFD8B3);

        if (phaseItem is Map) {
          phaseName = phaseItem['name']?.toString() ?? '';
          phaseBg = (phaseItem['bg'] as Color?) ?? const Color(0xFFFFD8B3);
        } else {
          phaseName = phaseItem.toString();
          if (phaseName == 'Luteal') {
            phaseBg = const Color(0xFFF3D5E4);
          } else if (phaseName == 'Menstrual') {
            phaseBg = const Color(0xFFFFC6C6);
          } else if (phaseName == 'Ovulation') {
            phaseBg = const Color(0xFFE8D4F0);
          } else {
            phaseBg = const Color(0xFFFFD8B3);
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: phaseBg,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.wellnessBrown,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                phaseName,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomChips(List<dynamic> symptoms) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: symptoms.map((symptom) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F9),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFFFD8E5), width: 1.0),
          ),
          child: Text(
            symptom.toString(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentChips(List<dynamic> equipmentList) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: equipmentList.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F9),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFFFD8E5), width: 1.0),
          ),
          child: Text(
            item.toString(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
          ),
        );
      }).toList(),
    );
  }
}
