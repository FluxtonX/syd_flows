import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 0; // 0 for Annual, 1 for Monthly
  bool _showSuccessBanner = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

  void _triggerSuccessBanner(String message) {
    setState(() {
      _bannerMessage = message;
      _showSuccessBanner = true;
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccessBanner = false;
          });
        }
      });
    });
  }

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
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Custom Header (Back button in white rounded square + Subscription title)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42.0,
                            height: 42.0,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.wellnessBrown.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.wellnessBrown,
                              size: 26.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Text(
                          'Subscription',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h24,

                    // 1. Premium Access Top Hero Card
                    _buildPremiumHeaderCard(),
                    AppSpacing.h24,

                    // 2. EXCLUSIVE FEATURES Section
                    _buildSectionHeader('EXCLUSIVE FEATURES'),
                    const SizedBox(height: 8.0),
                    _buildExclusiveFeaturesSection(),
                    AppSpacing.h24,

                    // 3. CHOOSE YOUR PLAN Section
                    _buildSectionHeader('CHOOSE YOUR PLAN'),
                    const SizedBox(height: 8.0),
                    _buildAnnualPlanCard(),
                    const SizedBox(height: 12.0),
                    _buildMonthlyPlanCard(),
                    AppSpacing.h24,

                    // 4. Start Free Trial CTA Button
                    SizedBox(
                      height: 52.0,
                      child: ElevatedButton(
                        onPressed: () {
                          _triggerSuccessBanner('Premium Subscription Activated!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C1E16),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: const Text(
                          'Start Free Trial',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // 5. Restore Purchase Link
                    GestureDetector(
                      onTap: () {
                        _triggerSuccessBanner('Purchases restored.');
                      },
                      child: Text(
                        'RESTORE PURCHASE',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 6. Terms & Disclaimer
                    Text(
                      'Cancel anytime. Secure payment. Privacy-first.\nBy continuing, you agree to our Terms of Service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),

              // Success Notification Banner
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                top: _showSuccessBanner ? 16.0 : -100.0,
                left: 16.0,
                right: 16.0,
                child: Center(
                  child: AppSuccessBanner(message: _bannerMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.wellnessBrown.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildPremiumHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF5F7), // Gentle pink left
            Color(0xFFFFD9E4), // Warm pink right
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFFF5B5CD),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF4ED),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'PREMIUM ACCESS',
                    style: TextStyle(
                      color: AppColors.wellnessBrown,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Syd Flows Studio Access',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 19.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Unlock a more Suggested\nfitness experience.',
                  style: TextStyle(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.75),
                    fontSize: 13.0,
                    height: 1.3,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          SvgPicture.asset(
            AppAssets.premiumBadge,
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildExclusiveFeaturesSection() {
    return Column(
      children: [
        // 1. Full width: Advanced Cycle Insights
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F9),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: const Color(0xFFF5B5CD),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD1DF),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFFC8455B),
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Cycle Insights',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Deep data correlation with your\nworkouts.',
                      style: TextStyle(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                        fontSize: 12.0,
                        height: 1.25,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // Row 1: Unlimited Workouts + More Holistic Instructors
        Row(
          children: [
            Expanded(
              child: Container(
                height: 130.0,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F9),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFF5B5CD),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE4D8),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          AppAssets.navWorkouts,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFB5613C),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Unlimited\nWorkouts',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Full library access.',
                      style: TextStyle(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.65),
                        fontSize: 11.0,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Container(
                height: 130.0,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F9),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFF5B5CD),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD1DF),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFC8455B),
                        size: 20.0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'More Holistic\nInstructors',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE3E6),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text(
                        'SOON',
                        style: TextStyle(
                          color: AppColors.wellnessBrown,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // Row 2: Progress Reports + Wellness Content
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F9),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFF5B5CD),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD1DF),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFFC8455B),
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Progress\nReports',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F9),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFF5B5CD),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE3DE),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF7A675C),
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Wellness\nContent',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnualPlanCard() {
    final isSelected = _selectedPlanIndex == 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.wellnessBrown : Colors.transparent,
            width: isSelected ? 1.5 : 0.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.wellnessBrown.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Annual Plan',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 19.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D0DD),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Color(0xFF8C2D43),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'First 7 days free, then \$59.99/yr',
              style: TextStyle(
                color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                fontSize: 13.0,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 14.0),
            Divider(
              color: AppColors.wellnessBrown.withValues(alpha: 0.08),
              height: 1.0,
            ),
            const SizedBox(height: 14.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$314.99',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 26.0,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  '/ month (billed annually)',
                  style: TextStyle(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPlanCard() {
    final isSelected = _selectedPlanIndex == 1;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFAECEF),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.wellnessBrown : Colors.transparent,
            width: isSelected ? 1.5 : 0.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.wellnessBrown.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Plan',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 19.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Flexible, cancel anytime',
              style: TextStyle(
                color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                fontSize: 13.0,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 14.0),
            Divider(
              color: AppColors.wellnessBrown.withValues(alpha: 0.08),
              height: 1.0,
            ),
            const SizedBox(height: 14.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$34.99',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 26.0,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  '/ month',
                  style: TextStyle(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.7),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
