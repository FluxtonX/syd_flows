import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../setup_flow/presentation/widgets/fitness_level_step.dart';
import '../../../setup_flow/presentation/widgets/goals_step.dart';
import '../../../setup_flow/presentation/widgets/slider_selection_step.dart';
import '../viewmodels/edit_profile_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EditProfileViewModel();
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
            content: Text('Could not set profile image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isFetching) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.wellnessBrown,
                  ),
                );
              }

              return Column(
                children: [
                  // Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: Row(
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
                                  color: AppColors.wellnessBrown.withValues(
                                    alpha: 0.05,
                                  ),
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
                          'Edit Profile',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error banner if any
                          if (_viewModel.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E8),
                                borderRadius: AppRadius.r12,
                                border: Border.all(
                                  color: const Color(0xFFF8B4B4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFE53E3E),
                                    size: 20,
                                  ),
                                  AppSpacing.w12,
                                  Expanded(
                                    child: Text(
                                      _viewModel.errorMessage!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF9B1C1C),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.h16,
                          ],

                          // Profile Photo Header
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final uid =
                                        AuthService.instance.currentUser?.uid;
                                    if (uid != null) {
                                      _showProfileImagePickerBottomSheet(uid);
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      ValueListenableBuilder<String?>(
                                        valueListenable: LocalStorageService
                                            .instance
                                            .profileImageNotifier,
                                        builder: (context, localImagePath, _) {
                                          final hasLocalFile =
                                              localImagePath != null &&
                                              localImagePath.isNotEmpty &&
                                              File(localImagePath).existsSync();

                                          ImageProvider? imageProvider;
                                          if (hasLocalFile) {
                                            imageProvider = FileImage(
                                              File(localImagePath),
                                            );
                                          }

                                          final initial =
                                              _viewModel
                                                  .nameController
                                                  .text
                                                  .isNotEmpty
                                              ? _viewModel
                                                    .nameController
                                                    .text[0]
                                                    .toUpperCase()
                                              : 'U';

                                          return Container(
                                            width: 80.0,
                                            height: 80.0,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.wellnessBrown
                                                      .withValues(alpha: 0.12),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: imageProvider != null
                                                  ? Image(
                                                      image: imageProvider,
                                                      width: 80.0,
                                                      height: 80.0,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        initial,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .wellnessPinkText,
                                                          fontSize: 32.0,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                          width: 26.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(
                                            color: AppColors.wellnessBrown,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.white,
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.wellnessBrown
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppColors.white,
                                              size: 13.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Tap to change photo',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.wellnessGray,
                                    fontSize: 11.0,
                                  ),
                                ),
                                AppSpacing.h24,
                              ],
                            ),
                          ),

                          // 1. Personal Info Section
                          _buildSectionHeader('PERSONAL INFO'),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppRadius.r24,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.wellnessBrown.withValues(
                                    alpha: 0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full Name',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.wellnessBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.h8,
                                TextField(
                                  controller: _viewModel.nameController,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.wellnessBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your name',
                                    filled: true,
                                    fillColor: AppColors.wellnessBeige
                                        .withValues(alpha: 0.3),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 14.0,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: AppRadius.r16,
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.r16,
                                      borderSide: const BorderSide(
                                        color: AppColors.wellnessPinkCategory,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.h24,

                          // 2. Cycle Preferences Section
                          _buildSectionHeader('CYCLE PREFERENCES'),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppRadius.r24,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.wellnessBrown.withValues(
                                    alpha: 0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cycle Length',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.wellnessBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.h4,
                                Text(
                                  'Average days from one period to the next',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.wellnessGray,
                                  ),
                                ),
                                AppSpacing.h16,
                                SliderSelectionStep(
                                  value: _viewModel.cycleLength,
                                  min: 15,
                                  max: 45,
                                  unitText: 'days',
                                  onChanged: _viewModel.setCycleLength,
                                  cardGradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.cycleLengthGradientTop,
                                      AppColors.cycleLengthGradientBottom,
                                    ],
                                  ),
                                  inactiveTrackColor: const Color(0xFFE6DACD),
                                ),
                                AppSpacing.h24,
                                Divider(
                                  color: AppColors.wellnessBrown.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                                AppSpacing.h16,
                                Text(
                                  'Period Length',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.wellnessBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.h4,
                                Text(
                                  'How many days your period usually lasts',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.wellnessGray,
                                  ),
                                ),
                                AppSpacing.h16,
                                SliderSelectionStep(
                                  value: _viewModel.periodLength,
                                  min: 2,
                                  max: 10,
                                  unitText: 'days',
                                  onChanged: _viewModel.setPeriodLength,
                                  cardGradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.periodLengthGradientTop,
                                      AppColors.periodLengthGradientBottom,
                                    ],
                                  ),
                                  inactiveTrackColor: const Color(0xFFFBF7F2),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.h24,

                          // 3. Fitness Level Section
                          _buildSectionHeader('FITNESS EXPERIENCE'),
                          FitnessLevelStep(
                            selectedLevel: _viewModel.fitnessLevel,
                            onLevelSelected: _viewModel.setFitnessLevel,
                          ),
                          AppSpacing.h24,

                          // 4. Goals Section
                          _buildSectionHeader('WELLNESS GOALS'),
                          GoalsStep(
                            selectedGoals: _viewModel.selectedGoals,
                            onGoalToggled: _viewModel.toggleGoal,
                          ),
                          AppSpacing.h32,
                        ],
                      ),
                    ),
                  ),

                  // Bottom Glowing Save Button
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      height: 50.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.r16,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.wellnessBrown.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 20.0,
                            spreadRadius: 1.0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _viewModel.isLoading
                            ? null
                            : () async {
                                final success = await _viewModel.saveProfile();
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile & preferences updated!',
                                      ),
                                      backgroundColor: AppColors.wellnessBrown,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wellnessBrown,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.r16,
                          ),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
}
