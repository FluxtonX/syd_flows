import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/workout_service.dart';
import '../../../workout/data/models/workout_model.dart';
import '../../../workout/presentation/screens/workout_detail_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<CompletedWorkoutRecord>>(
        stream: uid.isNotEmpty
            ? WorkoutService.instance.streamAllCompletedWorkouts(uid)
            : Stream.value([]),
        builder: (context, workoutSnapshot) {
          final workouts = workoutSnapshot.data ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('cycle_logs')
                      .snapshots()
                : const Stream.empty(),
            builder: (context, cycleSnapshot) {
              final cycleDocs = cycleSnapshot.data?.docs ?? [];

              // Collect all unique active date keys (YYYY-MM-DD)
              final Set<String> activeDateKeys = {};

              for (final w in workouts) {
                final dt = w.completedAt;
                final key =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                activeDateKeys.add(key);
              }

              for (final doc in cycleDocs) {
                activeDateKeys.add(doc.id);
              }

              final streakCount = WorkoutService.calculateStreakDays(
                activeDateKeys,
              );
              final totalMinutes = workouts.fold<int>(
                0,
                (acc, w) => acc + w.duration,
              );
              final totalWorkouts = workouts.length;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header
                    _buildHeader(),
                    AppSpacing.h24,

                    // 2. Row of 3 Stats Cards
                    _buildStatsRow(
                      streakCount: streakCount,
                      totalMinutes: totalMinutes,
                      totalWorkouts: totalWorkouts,
                    ),
                    AppSpacing.h24,

                    // 3. Activity Card (Weekly Bar Chart)
                    _buildActivityCard(workouts),
                    AppSpacing.h24,

                    // 4. Cycle Insights Card
                    _buildCycleInsightsCard(),
                    AppSpacing.h24,

                    // 5. Favorites Section
                    _buildFavoritesSection(uid),
                    AppSpacing.h24,

                    // 6. Achievements Section
                    _buildAchievementsSection(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Progress',
      style: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.wellnessBrown,
        fontWeight: FontWeight.bold,
        fontSize: 30.0,
      ),
    );
  }

  Widget _buildStatsRow({
    required int streakCount,
    required int totalMinutes,
    required int totalWorkouts,
  }) {
    return Row(
      children: [
        // Day Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5EC), // Soft pink
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.whatshot_rounded,
                  color: AppColors.wellnessPinkText,
                  size: 20.0,
                ),
                const SizedBox(height: 12.0),
                Text(
                  '$streakCount',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'DAY STREAK',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Minutes Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F2EB), // Soft beige
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.wellnessOrangeAccent,
                  size: 20.0,
                ),
                const SizedBox(height: 12.0),
                Text(
                  '$totalMinutes',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'MINUTES',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Workouts Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wellnessBrown.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                  size: 20.0,
                ),
                const SizedBox(height: 12.0),
                Text(
                  '$totalWorkouts',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'WORKOUTS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(List<CompletedWorkoutRecord> allWorkouts) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Activity title + Weekly badge only
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFFF08AAE),
                    width: 2.5,
                  ),
                ),
                child: Text(
                  'Weekly',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.h24,

          // Weekly Bar Chart
          _buildWeeklyBarChart(allWorkouts),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<CompletedWorkoutRecord> allWorkouts) {
    final now = DateTime.now();
    final mondayDate = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final mondayStart = DateTime(
      mondayDate.year,
      mondayDate.month,
      mondayDate.day,
      0,
      0,
      0,
    );
    final sundayEnd = mondayStart.add(
      const Duration(days: 7, microseconds: -1),
    );

    // Filter current week workouts
    final currentWeekWorkouts = allWorkouts.where((w) {
      return w.completedAt.isAfter(
            mondayStart.subtract(const Duration(seconds: 1)),
          ) &&
          w.completedAt.isBefore(sundayEnd);
    }).toList();

    final List<int> dayMinutes = List.filled(7, 0);
    for (final w in currentWeekWorkouts) {
      final idx = w.completedAt.weekday - 1;
      if (idx >= 0 && idx < 7) {
        dayMinutes[idx] += w.duration;
      }
    }

    int maxVal = 45;
    for (final m in dayMinutes) {
      if (m > maxVal) maxVal = m;
    }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 125.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final mins = dayMinutes[index];
          // Empty state (0 mins): barHeight is 0.0 => NO bar line!
          final double barHeight = mins > 0 ? (mins / maxVal) * 90.0 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: barHeight > 0.0
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 24.0,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08AAE),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(), // Empty state: NO bar line!
              ),
              const SizedBox(height: 8.0),
              Text(
                days[index],
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.0,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCycleInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cycle insights',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Where your energy lands across phases.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.wellnessGray,
              fontSize: 13.0,
            ),
          ),
          AppSpacing.h24,

          // Multi-ring circle chart centered
          Center(
            child: SizedBox(
              width: 170.0,
              height: 170.0,
              child: CustomPaint(painter: ConcentricRingsPainter()),
            ),
          ),
          AppSpacing.h24,

          // 2x2 Grid of details (Exact Figma Mockup Colors & Styling)
          Row(
            children: [
              Expanded(
                child: _buildPhaseSessionCard(
                  'MENSTRUAL',
                  '4 sessions',
                  AppColors.phaseMenstrual,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildPhaseSessionCard(
                  'FOLLICULAR',
                  '9 sessions',
                  AppColors.phaseFollicular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: _buildPhaseSessionCard(
                  'OVULATION',
                  '6 sessions',
                  AppColors.phaseOvulation,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildPhaseSessionCard(
                  'LUTEAL',
                  '7 sessions',
                  AppColors.phaseLuteal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSessionCard(String title, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(String uid) {
    return StreamBuilder<List<Workout>>(
      stream: uid.isNotEmpty
          ? WorkoutService.instance.streamFavorites(uid)
          : Stream.value([]),
      builder: (context, snapshot) {
        final favorites = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Favorites',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 12.0),
            if (favorites.isEmpty)
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: AppColors.wellnessBeige.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'No favorite workouts saved yet. Tap the ❤️ icon on any workout to save it here!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.wellnessGray,
                    fontSize: 13.0,
                  ),
                ),
              )
            else
              ...favorites.map((fav) {
                final cover = fav.imagePath.isNotEmpty
                    ? fav.imagePath
                    : (fav.videoId != null && fav.videoId!.isNotEmpty
                        ? 'https://img.youtube.com/vi/${fav.videoId}/hqdefault.jpg'
                        : 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=600&auto=format&fit=crop');

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(workout: fav),
                      ),
                    );
                  },
                  child: Container(
                    height: 90.0,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: cover.startsWith('http')
                                ? Image.network(
                                    cover,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color:
                                                  AppColors.wellnessPeachAccent,
                                            ),
                                  )
                                : Image.asset(
                                    cover,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color:
                                                  AppColors.wellnessPeachAccent,
                                            ),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.black.withValues(alpha: 0.2),
                                    AppColors.black.withValues(alpha: 0.75),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                            bottom: 16.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  fav.category.toUpperCase(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  fav.title,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '🕒 ${fav.duration}m  ·  ${fav.difficulty}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Achievements',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        const SizedBox(height: 12.0),

        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                'First Flow',
                'Completed your\nfirst workout',
                Icons.emoji_events_outlined,
                true,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildAchievementCard(
                '7-Day Streak',
                'Moved 7 days\nin a row',
                Icons.emoji_events_outlined,
                true,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildAchievementCard(
                'Cycle Aware',
                'Logged a full\ncycle',
                Icons.emoji_events_outlined,
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                'Strong Start',
                '10 strength\nsessions',
                Icons.emoji_events_outlined,
                false,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildAchievementCard(
                'Mindful Mover',
                '20 mobility\nsessions',
                Icons.emoji_events_outlined,
                false,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildAchievementCard(
                'Consistency Queen',
                '30-day streak',
                Icons.emoji_events_outlined,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    String title,
    String desc,
    IconData icon,
    bool unlocked,
  ) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        height: 135.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.wellnessBrown.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: unlocked
                    ? const Color(0xFFFFE5EC)
                    : const Color(0xFFF7F2EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: unlocked
                    ? AppColors.wellnessPinkText
                    : AppColors.wellnessBrown.withValues(alpha: 0.35),
                size: 20.0,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                fontSize: 9.0,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConcentricRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final configs = [
      _RingConfig(
        radius: 70.0,
        color: AppColors.phaseFollicular, // Follicular (Outer ring)
        sweepAngle: 280.0,
        strokeWidth: 8.0,
      ),
      _RingConfig(
        radius: 58.0,
        color: AppColors.phaseLuteal, // Luteal
        sweepAngle: 230.0,
        strokeWidth: 8.0,
      ),
      _RingConfig(
        radius: 46.0,
        color: AppColors.phaseOvulation, // Ovulation
        sweepAngle: 170.0,
        strokeWidth: 8.0,
      ),
      _RingConfig(
        radius: 34.0,
        color: AppColors.phaseMenstrual, // Menstrual (Inner ring)
        sweepAngle: 210.0,
        strokeWidth: 8.0,
      ),
    ];

    for (var conf in configs) {
      // Draw background track
      paint.color = conf.color.withValues(alpha: 0.15);
      paint.strokeWidth = conf.strokeWidth;
      canvas.drawCircle(center, conf.radius, paint);

      // Draw active arc
      paint.color = conf.color;
      final startAngle = -math.pi / 2;
      final sweepAngleRad = conf.sweepAngle * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: conf.radius),
        startAngle,
        sweepAngleRad,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingConfig {
  final double radius;
  final Color color;
  final double sweepAngle;
  final double strokeWidth;

  _RingConfig({
    required this.radius,
    required this.color,
    required this.sweepAngle,
    required this.strokeWidth,
  });
}
