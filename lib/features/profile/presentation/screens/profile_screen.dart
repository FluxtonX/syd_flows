import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syd_flow/core/constants/app_assets.dart';
import 'package:syd_flow/core/services/local_storage_service.dart';
import 'package:syd_flow/features/profile/presentation/screens/settings_screen.dart';
import 'package:syd_flow/features/profile/presentation/screens/subscription_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/workout_service.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      LocalStorageService.instance.getLocalProfileImagePath(uid);
    }
  }

  void _showProfileImagePickerBottomSheet(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Profile Photo',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Upload or change your profile image',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.wellnessGray,
                  ),
                ),
                const SizedBox(height: 24.0),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  tileColor: const Color(0xFFFAF5F0),
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7ECE1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.wellnessBrown,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    await _pickAndSaveImage(ImageSource.gallery, uid);
                  },
                ),
                const SizedBox(height: 12.0),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  tileColor: const Color(0xFFFFF0F5),
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD1DF),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.wellnessPinkText,
                    ),
                  ),
                  title: Text(
                    'Take Photo with Camera',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    await _pickAndSaveImage(ImageSource.camera, uid);
                  },
                ),
                if (LocalStorageService.instance.profileImageNotifier.value !=
                    null) ...[
                  const SizedBox(height: 12.0),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    tileColor: const Color(0xFFFDE8E8),
                    leading: Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    title: Text(
                      'Remove Profile Photo',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFE53E3E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      await LocalStorageService.instance
                          .removeLocalProfileImage(uid);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile photo removed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSaveImage(ImageSource source, String uid) async {
    try {
      final savedPath = await LocalStorageService.instance
          .pickAndSaveProfileImage(uid, source);
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppColors.wellnessBrown,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showLogoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                AppSpacing.h24,

                // Logout Icon Container
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD1DF),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.wellnessPinkText,
                      size: 24.0,
                    ),
                  ),
                ),
                AppSpacing.h24,

                // Title
                Text(
                  'Log Out?',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),

                // Description
                Text(
                  'Are you sure you want to log out of your SYD FLOWS account?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.wellnessGray,
                  ),
                ),
                AppSpacing.h24,

                // Log out button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop(); // Close modal sheet
                      await AuthService.instance.signOut();
                      navigator.pushNamedAndRemoveUntil(
                        RouteNames.auth,
                        (route) => false,
                      );
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
                      'Log Out',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.r16,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            // 1. Title Bar (Profile + Settings Gear Icon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.wellnessBrown,
                    size: 24.0,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                    padding: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(
                        color: AppColors.wellnessBrown.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.h24,

            // 2. Avatar Card (Gradient)
            _buildAvatarCard(),
            AppSpacing.h24,

            // 3. Edit Profile & Preferences Card
            _buildSectionHeader('PROFILE & PREFERENCES'),
            _buildOptionCard(
              iconWidget: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.wellnessBrown,
                size: 20.0,
              ),
              title: 'Edit Profile & Preferences',
              subtitle: 'Name, goals, cycle preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            AppSpacing.h24,

            // 3. Notifications Category Card
            _buildSectionHeader('NOTIFICATION'),
            _buildOptionCard(
              iconWidget: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.wellnessBrown,
                size: 20.0,
              ),
              title: 'Notifications',
              subtitle: 'Manage notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            AppSpacing.h24,

            // 4. Subscription Category Card
            _buildSectionHeader('SUBSCRIPTION'),
            _buildOptionCard(
              iconWidget: SvgPicture.asset(
                AppAssets.profilePremium,
                width: 20.0,
                height: 20.0,
              ),
              title: 'Syd Flows Premium',
              subtitle: 'Renews Aug 12',
              isPremium: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
            AppSpacing.h24,

            // 5. Activity Category Card
            _buildSectionHeader('ACTIVITY'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.r24,
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
                  _buildSubOptionRow(
                    iconWidget: SvgPicture.asset(
                      AppAssets.profileAchievements,
                      width: 20.0,
                      height: 20.0,
                    ),
                    title: 'Achievements',
                    trailingText: '3 of 6 unlocked',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'See Achievements under Progress Insights!',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Divider(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.06),
                    height: 1.0,
                    indent: 64.0,
                  ),
                  _buildSubOptionRow(
                    iconWidget: const Icon(
                      Icons.history_rounded,
                      color: AppColors.wellnessBrown,
                      size: 20.0,
                    ),
                    title: 'Workout History',
                    trailingText: '26 sessions',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout history details coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.h24,

            // 6. Support Category Card
            _buildSectionHeader('SUPPORT'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.r24,
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
                  _buildSubOptionRow(
                    iconWidget: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.wellnessBrown,
                      size: 20.0,
                    ),
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.06),
                    height: 1.0,
                    indent: 64.0,
                  ),
                  _buildSubOptionRow(
                    iconWidget: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.wellnessPinkText,
                      size: 20.0,
                    ),
                    title: 'Log out',
                    textColor: AppColors.wellnessPinkText,
                    onTap: _showLogoutBottomSheet,
                  ),
                ],
              ),
            ),
            AppSpacing.h32,

            // Version info at bottom
            Text(
              'SYD FLOWS v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.wellnessGray.withValues(alpha: 0.5),
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.wellnessGray.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  String _formatMemberSince(DateTime? date) {
    if (date == null) return 'Member since 2026';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = months[date.month - 1];
    return 'Member since $monthName ${date.year}';
  }

  Widget _buildAvatarCard() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return _buildAvatarCardContent(
        name: 'Guest User',
        subtitle: 'Not signed in',
        initial: 'G',
        photoUrl: null,
      );
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

        final name = rawName.isNotEmpty
            ? rawName
            : (email.isNotEmpty ? email.split('@').first : 'User');

        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final subtitle = email.isNotEmpty
            ? email
            : _formatMemberSince(currentUser.metadata.creationTime);

        return _buildAvatarCardContent(
          name: name,
          subtitle: subtitle,
          initial: initial,
          photoUrl: photoUrl,
        );
      },
    );
  }

  Widget _buildAvatarCardContent({
    required String name,
    required String subtitle,
    required String initial,
    required String? photoUrl,
  }) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.r24,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD1DF), // Warm pink left
            Color(0xFFFFF0F5), // Soft lavender pink right
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessPinkText.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Avatar Initial + Name
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final uid = AuthService.instance.currentUser?.uid;
                  if (uid != null) {
                    _showProfileImagePickerBottomSheet(uid);
                  }
                },
                child: Stack(
                  children: [
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
                          width: 60.0,
                          height: 60.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.wellnessBrown.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: imageProvider != null
                                ? Image(
                                    image: imageProvider,
                                    width: 60.0,
                                    height: 60.0,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: AppColors.wellnessPinkText,
                                              fontSize: 24.0,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                        ),
                                  )
                                : Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: AppColors.wellnessPinkText,
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22.0,
                        height: 22.0,
                        decoration: BoxDecoration(
                          color: AppColors.wellnessBrown,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.wellnessBrown.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.white,
                            size: 11.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.wellnessGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.h24,

          // Stats inside Avatar Card (Live Real-Time Data)
          StreamBuilder<List<CompletedWorkoutRecord>>(
            stream: uid.isNotEmpty
                ? WorkoutService.instance.streamAllCompletedWorkouts(uid)
                : Stream.value([]),
            builder: (context, workoutSnapshot) {
              final workouts = workoutSnapshot.data ?? [];
              final workoutsCount = workouts.length;
              final totalMinutes = workouts.fold<int>(
                0,
                (acc, w) => acc + w.duration,
              );

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: uid.isNotEmpty
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('cycle_logs')
                          .snapshots()
                          .handleError((_) => null)
                    : const Stream.empty(),
                builder: (context, cycleSnapshot) {
                  final cycleDocs = cycleSnapshot.data?.docs ?? [];
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

                  return Row(
                    children: [
                      Expanded(
                        child: _buildAvatarStat('$workoutsCount', 'WORKOUTS'),
                      ),
                      _buildAvatarDivider(),
                      Expanded(
                        child: _buildAvatarStat('$totalMinutes', 'MINUTES'),
                      ),
                      _buildAvatarDivider(),
                      Expanded(
                        child: _buildAvatarStat('$streakCount', 'STREAK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.wellnessBrown.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 9.0,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarDivider() {
    return Container(
      width: 1.0,
      height: 24.0,
      color: AppColors.wellnessBrown.withValues(alpha: 0.08),
    );
  }

  Widget _buildOptionCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: isPremium ? const Color(0xFFFDE4EC) : AppColors.white,
          borderRadius: AppRadius.r24,
          boxShadow: [
            BoxShadow(
              color: AppColors.wellnessBrown.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                color: isPremium ? AppColors.white : const Color(0xFFF7ECE1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(child: iconWidget),
            ),
            AppSpacing.w16,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.wellnessGray,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.wellnessGray,
              size: 22.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOptionRow({
    required Widget iconWidget,
    required String title,
    String? trailingText,
    Color? textColor,
    Color? iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFFF7ECE1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(child: iconWidget),
            ),
            AppSpacing.w16,
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor ?? AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.wellnessGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8.0),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.wellnessGray,
              size: 22.0,
            ),
          ],
        ),
      ),
    );
  }
}
