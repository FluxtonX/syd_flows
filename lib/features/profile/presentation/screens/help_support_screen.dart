import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _showSuccessBanner = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

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
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.wellnessBrown,
              size: 28.0,
            ),
          ),
          title: Text(
            'Help & Support',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F2EB), // Soft beige card background
                      borderRadius: AppRadius.r24,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Headset support icon in circle badge
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.wellnessOrangeAccent,
                            size: 32.0,
                          ),
                        ),
                        AppSpacing.h24,

                        // Title
                        Text(
                          'Need immediate help?',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        // Subtitle description
                        Text(
                          'Our dedicated team is ready to assist you with any questions or concerns.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.wellnessGray,
                            height: 1.4,
                          ),
                        ),
                        AppSpacing.h24,

                        // Contact support button
                        SizedBox(
                          width: double.infinity,
                          height: 48.0,
                          child: ElevatedButton(
                            onPressed: () {
                              _triggerSuccessBanner('Support Ticket Created!');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.wellnessBrown,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.r16,
                              ),
                            ),
                            child: Text(
                              'Contact Support',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Success banner overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              top: _showSuccessBanner 
                  ? MediaQuery.of(context).padding.top + 12.0 
                  : -100.0,
              left: 16.0,
              right: 16.0,
              child: Center(
                child: AppSuccessBanner(message: _bannerMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
