import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../widgets/splash_logo_card.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splashDelay,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) async {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final hasCompleted = await UserService.instance.hasUserCompletedSetup(user.uid);
        if (hasCompleted) {
          NavigationService.pushReplacementNamed(RouteNames.home);
        } else {
          NavigationService.pushReplacementNamed(RouteNames.setupFlow);
        }
      } else {
        NavigationService.pushReplacementNamed(RouteNames.auth);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Animated Logo Card
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: const SplashLogoCard(),
                    ),
                  );
                },
              ),

              AppSpacing.h32,

              // Animated Tagline ("Find Your Flow") matching Figma
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFade.value,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Find Your ',
                            style: TextStyle(color: AppColors.wellnessBrown),
                          ),
                          TextSpan(
                            text: 'Flow',
                            style: TextStyle(
                              color: AppColors.wellnessPinkAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              // Progress indicator at the bottom matching Figma
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: SizedBox(
                        height: 7.0,
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          backgroundColor: const Color(
                            0xFF8C654D,
                          ).withValues(alpha: 0.6),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF5B5CD),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
