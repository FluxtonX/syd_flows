import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
            'Terms of Service',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.r24,
              boxShadow: [
                BoxShadow(
                  color: AppColors.wellnessBrown.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTermSection(
                  title: 'ACCEPTANCE',
                  content:
                      'By using Syd Flows, you agree to these Terms and our Privacy Policy.',
                ),
                _buildTermSection(
                  title: 'Purpose',
                  content:
                      'Syd Flows provides personalized fitness and wellness recommendations based on your menstrual cycle. It is not a medical or diagnostic service. Always consult a healthcare professional for medical advice.',
                ),
                _buildTermSection(
                  title: 'Your Responsibility',
                  content:
                      'You agree to provide accurate information, keep your account secure, and use the app and its recommendations responsibly.',
                ),
                _buildTermSection(
                  title: 'Subscription',
                  content:
                      'Premium plans renew automatically unless canceled through your Google Play or App Store account settings at least 24 hours before the renewal date.',
                ),
                _buildTermSection(
                  title: 'Privacy',
                  content:
                      'Your personal and biological data is processed securely and in accordance with our Privacy Policy to generate phase-specific suggestions.',
                ),
                _buildTermSection(
                  title: 'Updates',
                  content:
                      'These Terms may be updated from time to time. Continued use of Syd Flows means you accept the updated Terms.',
                ),
                _buildTermSection(
                  title: 'Contact',
                  content:
                      'If you have any questions, reach out to support@sydflow.app',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermSection({
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
