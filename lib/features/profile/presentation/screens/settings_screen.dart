import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/gradient_background.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _dailyReminder = true;
  int _selectedBottomTab = 4; // Profile tab

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _selectedBottomTab,
          onTap: (index) {
            setState(() {
              _selectedBottomTab = index;
            });
            Navigator.pop(context);
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Custom Header matching Figma
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
                      'Settings',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                  ],
                ),
                AppSpacing.h24,

                // 1. ACCOUNT Section
                _buildSectionHeader('ACCOUNT'),
                Container(
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
                    children: [
                      _buildNavigationRow(
                        title: 'Edit Profile & Preferences',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.h24,

                // 1. NOTIFICATIONS Section
                _buildSectionHeader('NOTIFICATIONS'),
                Container(
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
                    children: [
                      _buildSwitchRow(
                        title: 'Push notifications',
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                          });
                        },
                      ),
                      Divider(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.06),
                        height: 1.0,
                        indent: 16.0,
                        endIndent: 16.0,
                      ),
                      _buildSwitchRow(
                        title: 'Daily move reminder',
                        value: _dailyReminder,
                        onChanged: (val) {
                          setState(() {
                            _dailyReminder = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.h24,

                // 2. ABOUT Section
                _buildSectionHeader('ABOUT'),
                Container(
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
                    children: [
                      _buildNavigationRow(
                        title: 'About Syd Flows',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.06),
                        height: 1.0,
                        indent: 16.0,
                        endIndent: 16.0,
                      ),
                      _buildNavigationRow(
                        title: 'Terms of Service',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsOfServiceScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.06),
                        height: 1.0,
                        indent: 16.0,
                        endIndent: 16.0,
                      ),
                      _buildTextRow(
                        title: 'Version',
                        value: '1.0.0',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h32,

                // 3. Delete Account Card matching Figma
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deletion is locked for security.'),
                        backgroundColor: AppColors.wellnessPinkText,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
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
                    child: Text(
                      'Delete account',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFC8455B),
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
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

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w500,
              fontSize: 15.0,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF4B2E16),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.wellnessBrown.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.w500,
                fontSize: 15.0,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.wellnessBrown.withValues(alpha: 0.6),
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextRow({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.w500,
              fontSize: 15.0,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessBrown.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              fontSize: 15.0,
            ),
          ),
        ],
      ),
    );
  }
}
