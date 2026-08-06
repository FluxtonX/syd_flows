import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../viewmodels/setup_flow_view_model.dart';
import '../widgets/equipment_step.dart';
import '../widgets/first_period_step.dart';
import '../widgets/fitness_level_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/privacy_step.dart';
import '../widgets/slider_selection_step.dart';

class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key});

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  late final SetupFlowViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SetupFlowViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top progress bar and back button area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_viewModel.currentStep == 0) {
                              NavigationService.pop();
                            } else {
                              _viewModel.previousStep();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.wellnessBrown,
                            size: 24.0,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                            ),
                            child: ClipRRect(
                              borderRadius: AppRadius.rCircular,
                              child: SizedBox(
                                height: 6.0,
                                child: LinearProgressIndicator(
                                  value: _viewModel.progress,
                                  backgroundColor: AppColors.wellnessBeige
                                      .withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors
                                        .wellnessPinkCategory, // Figma active progress color
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${_viewModel.currentStep + 1}/7',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.wellnessGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.w8,
                      ],
                    ),
                  ),

                  // Header and content area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16.0),

                          // Step indicator label
                          Text(
                            'STEP ${_viewModel.currentStep + 1}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.wellnessPinkCategory,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          AppSpacing.h8,

                          // Step title
                          Text(
                            _getStepTitle(_viewModel.currentStep),
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.wellnessBrown,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),

                          // Step subtitle (if present)
                          if (_getStepSubtitle(
                            _viewModel.currentStep,
                          ).isNotEmpty) ...[
                            AppSpacing.h8,
                            Text(
                              _getStepSubtitle(_viewModel.currentStep),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.wellnessGray,
                              ),
                            ),
                          ],

                          const SizedBox(height: 28.0),

                          // Dynamic Step Content with Cross-fade transition
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: _buildStepContent(_viewModel.currentStep),
                          ),
                          const SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Button Area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.l,
                      AppSpacing.xl,
                    ),
                    child: Container(
                      height: 48.0,
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
                        onPressed: () {
                          _viewModel.nextStep(() {
                            NavigationService.pushNamedAndRemoveUntil(
                              RouteNames.home,
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wellnessBrown,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.r16,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            AppSpacing.w8,
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18.0,
                              color: AppColors.white,
                            ),
                          ],
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

  // Helper title mapping
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'First period';
      case 1:
        return 'Cycle length';
      case 2:
        return 'Period length';
      case 3:
        return 'Fitness level';
      case 4:
        return 'Goals';
      case 5:
        return 'Equipment';
      case 6:
        return 'Privacy';
      default:
        return '';
    }
  }

  // Helper subtitle mapping
  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'When did your last period start?';
      case 1:
        return 'Average days from one period to the next.';
      case 2:
        return 'How many days does your period usually last?';
      case 3:
        return 'This helps us calibrate your sessions.';
      case 4:
        return 'Pick what matters most. Choose any.';
      case 5:
        return 'What do you have at home?';
      case 6:
        return ''; // Handled in privacy card itself
      default:
        return '';
    }
  }

  // Build the active step page
  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return FirstPeriodStep(
          key: const ValueKey('Step1'),
          selectedDate: _viewModel.lastPeriodStart,
          onDateSelected: _viewModel.setLastPeriodStart,
        );
      case 1:
        return SliderSelectionStep(
          key: const ValueKey('Step2'),
          value: _viewModel.cycleLength,
          min: 15,
          max: 45,
          unitText: 'days',
          onChanged: _viewModel.setCycleLength,
          cardGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cycleLengthGradientTop, // Figma #F5E6D3 top
              AppColors.cycleLengthGradientBottom, // Figma #FBF7F2 bottom
            ],
          ),
          inactiveTrackColor: const Color(0xFFE6DACD),
        );
      case 2:
        return SliderSelectionStep(
          key: const ValueKey('Step3'),
          value: _viewModel.periodLength,
          min: 2,
          max: 10,
          unitText: 'days',
          onChanged: _viewModel.setPeriodLength,
          cardGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.periodLengthGradientTop, // Figma #F08AAE top
              AppColors.periodLengthGradientBottom, // Figma #FFE1EC bottom
            ],
          ),
          inactiveTrackColor: const Color(
            0xFFFBF7F2,
          ), // Figma #FBF7F2 inactive track
        );
      case 3:
        return FitnessLevelStep(
          key: const ValueKey('Step4'),
          selectedLevel: _viewModel.fitnessLevel,
          onLevelSelected: _viewModel.setFitnessLevel,
        );
      case 4:
        return GoalsStep(
          key: const ValueKey('Step5'),
          selectedGoals: _viewModel.selectedGoals,
          onGoalToggled: _viewModel.toggleGoal,
        );
      case 5:
        return EquipmentStep(
          key: const ValueKey('Step6'),
          selectedEquipment: _viewModel.selectedEquipment,
          onEquipmentToggled: _viewModel.toggleEquipment,
        );
      case 6:
        return const PrivacyStep(key: ValueKey('Step7'));
      default:
        return const SizedBox.shrink();
    }
  }
}
