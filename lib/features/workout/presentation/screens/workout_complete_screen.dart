import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/services/auth_service.dart';
import '../screens/workout_screen.dart';

class ConfettiParticle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  double spinSpeed;
  Color color;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.spinSpeed,
    required this.color,
  });
}

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Vibrant celebration colors
    final colors = [
      const Color(0xFFC75D85), // Wellness pink
      const Color(0xFFE2A45C), // Wellness orange
      const Color(0xFF6BCB77), // Soft green
      const Color(0xFFFFD1DF), // Soft pink
      const Color(0xFF4D96FF), // Soft blue
      const Color(0xFFFFD93D), // Yellow
    ];

    for (int i = 0; i < 70; i++) {
      _particles.add(
        ConfettiParticle(
          x: _random.nextDouble(),
          y:
              _random.nextDouble() *
              -1.2, // Start above the screen at different heights
          size: _random.nextDouble() * 10.0 + 6.0,
          speed: _random.nextDouble() * 0.12 + 0.05,
          angle: _random.nextDouble() * math.pi * 2,
          spinSpeed: (_random.nextDouble() - 0.5) * 6.0,
          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles position
        for (var particle in _particles) {
          particle.y += particle.speed * 0.035;
          particle.angle += particle.spinSpeed * 0.02;
          // Reset if it goes off bottom screen
          if (particle.y > 1.1) {
            particle.y = -0.1;
            particle.x = _random.nextDouble();
          }
        }

        return CustomPaint(
          painter: ConfettiPainter(_particles),
          child: Container(),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.y < -0.1 || p.y > 1.1) continue;

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.angle);

      paint.color = p.color;
      // Draw rectangular confetti piece
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WorkoutCompleteScreen extends StatefulWidget {
  final Workout workout;
  final int duration;
  final int calories;

  const WorkoutCompleteScreen({
    super.key,
    required this.workout,
    required this.duration,
    required this.calories,
  });

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> {
  final bool _showSuccessBanner = false;
  final String _bannerMessage = '';
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Confetti Animation Layer
            const Positioned.fill(child: ConfettiWidget()),

            // 2. Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Heart Card in Center (Increased size matching mockup)
                    Center(
                      child: Container(
                        width: 120.0,
                        height: 120.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DF),
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.wellnessPinkText.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            color: AppColors.wellnessBrown,
                            size: 52.0,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.h32,

                    // Celebration Text
                    Builder(
                      builder: (context) {
                        final user = AuthService.instance.currentUser;
                        final rawName = user?.displayName ?? '';
                        final firstName = rawName.trim().isNotEmpty
                            ? (rawName.contains(' ') ? rawName.split(' ').first : rawName)
                            : '';
                        final message = firstName.isNotEmpty
                            ? 'Beautiful work, $firstName'
                            : 'Beautiful work!';
                        return Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 28.0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // Subtitle text (Matching exact Figma mockup)
                    Text(
                      'Congratulations you have completed\nfor today.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.8),
                        fontSize: 16.0,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(),

                    // Done button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wellnessBrown,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                      ),
                      child: Text(
                        'Done',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    AppSpacing.h32,
                  ],
                ),
              ),
            ),

            // 3. Success Banner Layer
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              top: _showSuccessBanner
                  ? MediaQuery.of(context).padding.top + 20.0
                  : -100.0,
              left: 16.0,
              right: 16.0,
              child: Center(child: AppSuccessBanner(message: _bannerMessage)),
            ),
          ],
        ),
      ),
    );
  }
}
