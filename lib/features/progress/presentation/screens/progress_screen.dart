import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (Title only, no Level code)
            _buildHeader(),
            AppSpacing.h24,

            // 2. Row of 3 Stats Cards
            _buildStatsRow(),
            AppSpacing.h24,

            // 3. Activity Card (Weekly Bar Chart ONLY)
            _buildActivityCard(),
            AppSpacing.h24,

            // 4. Cycle Insights Card (Exact Figma Mockup Colors & Rings)
            _buildCycleInsightsCard(),
            AppSpacing.h24,

            // 5. Favorites Section
            _buildFavoritesSection(),
            AppSpacing.h24,

            // 6. Achievements Section
            _buildAchievementsSection(),
          ],
        ),
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

  Widget _buildStatsRow() {
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
                  '12',
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
                  '248',
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
                  '26',
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

  Widget _buildActivityCard() {
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
          _buildWeeklyBarChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    final weeklyData = [
      _BarData('Mon', 18.0),
      _BarData('Tue', 28.0),
      _BarData('Wed', 22.0),
      _BarData('Thu', 24.0),
      _BarData('Fri', 20.0),
      _BarData('Sat', 50.0),
      _BarData('Sun', 12.0),
    ];

    final maxVal = weeklyData.map((d) => d.value).reduce(math.max);

    return SizedBox(
      height: 125.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeklyData.map((data) {
          final barHeight = maxVal > 0 ? (data.value / maxVal) * 90.0 : 0.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24.0,
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF08AAE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                data.day,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.0,
                ),
              ),
            ],
          );
        }).toList(),
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

  Widget _buildFavoritesSection() {
    final favorites = [
      _FavoriteWorkout(
        title: 'Sunrise Flow Yoga',
        category: 'YOGA',
        imagePath: 'assets/images/workout/sunrise_flow.png',
        difficulty: 'Gentle',
        duration: 22,
      ),
      _FavoriteWorkout(
        title: 'Pilates Core Reset',
        category: 'PILATES',
        imagePath: 'assets/images/workout/pilates_core.png',
        difficulty: 'Moderate',
        duration: 28,
      ),
    ];

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
        ...favorites.map(
          (fav) => Container(
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
                    child: Image.asset(fav.imagePath, fit: BoxFit.cover),
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
                          fav.category,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
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
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '🕒 ${fav.duration}m  ·  ${fav.difficulty}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
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
        ),
      ],
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

class _FavoriteWorkout {
  final String title;
  final String category;
  final String imagePath;
  final String difficulty;
  final int duration;

  _FavoriteWorkout({
    required this.title,
    required this.category,
    required this.imagePath,
    required this.difficulty,
    required this.duration,
  });
}

class _BarData {
  final String day;
  final double value;

  _BarData(this.day, this.value);
}
