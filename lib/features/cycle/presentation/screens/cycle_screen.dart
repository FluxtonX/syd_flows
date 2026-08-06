import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../viewmodels/cycle_view_model.dart';

enum CyclePhase { menstrual, follicular, ovulation, luteal }

class DayJournal {
  final List<String> moods;
  final List<String> symptoms;
  final double energy;
  final String notes;

  DayJournal({
    required this.moods,
    required this.symptoms,
    required this.energy,
    required this.notes,
  });

  bool get isEmpty => moods.isEmpty && symptoms.isEmpty && notes.isEmpty;

  String get summaryText {
    final parts = <String>[];
    if (moods.isNotEmpty) {
      parts.add('Mood: ${moods.join(", ")}');
    }
    if (symptoms.isNotEmpty) {
      parts.add('Symptoms: ${symptoms.join(", ")}');
    }
    parts.add('Energy: ${(energy * 100).toInt()}%');
    if (notes.isNotEmpty) {
      parts.add('Notes: "$notes"');
    }
    return parts.join(' • ');
  }
}

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  late final CycleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CycleViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Phase helper mapping matching Figma design
  CyclePhase _getDayPhase(int day) {
    if ((day >= 1 && day <= 5) || (day >= 29 && day <= 31)) {
      return CyclePhase.menstrual;
    } else if (day >= 6 && day <= 13) {
      return CyclePhase.follicular;
    } else if (day >= 14 && day <= 16) {
      return CyclePhase.ovulation;
    } else {
      return CyclePhase.luteal;
    }
  }

  Color _getPhaseColor(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return AppColors.phaseMenstrual;
      case CyclePhase.follicular:
        return AppColors.phaseFollicular;
      case CyclePhase.ovulation:
        return AppColors.phaseOvulation;
      case CyclePhase.luteal:
        return AppColors.phaseLuteal;
    }
  }

  Color _getPhaseTextColor(CyclePhase phase) {
    return AppColors.white;
  }

  String _getPhaseName(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  void _showLogTodaySheet() async {
    final selectedDay = _viewModel.selectedDay;
    final initialJournal =
        _viewModel.journalEntries[selectedDay] ??
        DayJournal(moods: [], symptoms: [], energy: 0.6, notes: '');

    final result = await showModalBottomSheet<DayJournal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      showDragHandle: true,
      builder: (context) =>
          _LogTodayBottomSheet(initialJournal: initialJournal),
    );

    if (result != null) {
      _viewModel.saveLog(selectedDay, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final selectedDay = _viewModel.selectedDay;
        final journalEntries = _viewModel.journalEntries;
        final showSuccessBanner = _viewModel.showSuccessBanner;

        // Generate July 2026 calendar days: 1 to 31
        // July 1, 2026 is a Wednesday.
        // 0 represents empty space at start (Sunday, Monday, Tuesday are empty = 3 slots)
        final List<int> calendarDays = [
          0, 0, 0, // Empty spaces
          ...List.generate(31, (index) => index + 1),
        ];

        final currentPhase = _getDayPhase(selectedDay);
        final hasEntry = journalEntries.containsKey(selectedDay);
        final currentJournal = journalEntries[selectedDay];

        return Scaffold(
          backgroundColor: AppColors.transparent,
          body: GradientBackground(
            child: Stack(
              children: [
                // Scrollable Content
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.l,
                      AppSpacing.l,
                    ),
                    // Standard bottom spacing
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSpacing.h16,
                        _buildAppBar(),
                        AppSpacing.h24,
                        _buildCalendarCard(calendarDays, selectedDay),
                        AppSpacing.h24,
                        _buildSelectedDayDetailCard(
                          selectedDay,
                          currentPhase,
                          hasEntry,
                          currentJournal,
                        ),
                        AppSpacing.h24,
                        _buildPredictionsCard(),
                      ],
                    ),
                  ),
                ),

                // Top Success Banner ("Saved to your cycle journal")
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  top: showSuccessBanner
                      ? MediaQuery.of(context).padding.top + 12.0
                      : -100.0,
                  left: 16.0,
                  right: 16.0,
                  child: _buildSuccessBanner(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Success Banner ---
  Widget _buildSuccessBanner() {
    return const AppSuccessBanner(message: 'Saved to your cycle journal');
  }

  // --- AppBar ---
  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Cycle',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        // + Log today button matching exact Figma properties
        GestureDetector(
          onTap: _showLogTodaySheet,
          child: Container(
            height: 40.0,
            // Fixed 40px height from Figma
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // 16px horizontal padding from Figma
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.logTodayGradient,
              ),
              borderRadius: AppRadius.r8, // 8px radius from Figma
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF08AAE).withValues(alpha: 0.32),
                  // #F08AAE @ 32%
                  offset: const Offset(0, 12),
                  // Y: 12
                  blurRadius: 40.0,
                  // Blur: 40
                  spreadRadius: -8.0, // Spread: -8
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: AppColors.wellnessBrown,
                  size: 16,
                ),
                const SizedBox(width: 6.0), // 6px gap from Figma
                Text(
                  'Log today',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Calendar Card ---
  Widget _buildCalendarCard(List<int> calendarDays, int selectedDay) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.05),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month navigation selector: < July 2026 >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.wellnessGray,
                  size: 24,
                ),
              ),
              Text(
                'July 2026',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.wellnessGray,
                  size: 24,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          // Weekday Labels: S M T W T F S
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel(label: 'S'),
              _WeekdayLabel(label: 'M'),
              _WeekdayLabel(label: 'T'),
              _WeekdayLabel(label: 'W'),
              _WeekdayLabel(label: 'T'),
              _WeekdayLabel(label: 'F'),
              _WeekdayLabel(label: 'S'),
            ],
          ),
          AppSpacing.h8,
          // Days Grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 1.0,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              if (day == 0) return const SizedBox.shrink();

              final phase = _getDayPhase(day);
              final isSelected = day == selectedDay;

              return GestureDetector(
                onTap: () {
                  _viewModel.setSelectedDay(day);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : _getPhaseColor(phase),
                    borderRadius: BorderRadius.circular(8.0),
                    // Rounded square matching mockup
                    border: isSelected
                        ? Border.all(color: AppColors.wellnessBrown, width: 2.0)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.wellnessBrown
                              : _getPhaseTextColor(phase),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      if (phase == CyclePhase.menstrual) ...[
                        const SizedBox(height: 2.0),
                        Container(
                          width: 4.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.wellnessPinkText
                                : AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          AppSpacing.h24,
          // Legend below calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(AppColors.phaseMenstrual, 'Menstrual'),
              AppSpacing.w8,
              _buildLegendItem(AppColors.phaseFollicular, 'Follicular'),
              AppSpacing.w8,
              _buildLegendItem(AppColors.phaseOvulation, 'Ovulation'),
              AppSpacing.w8,
              _buildLegendItem(AppColors.phaseLuteal, 'Luteal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(
              2.0,
            ), // Rounded square legend dots
          ),
        ),
        AppSpacing.w4,
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.wellnessGray,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- Selected Day Details Card ---
  Widget _buildSelectedDayDetailCard(
    int selectedDay,
    CyclePhase phase,
    bool hasEntry,
    DayJournal? journal,
  ) {
    final Color badgeBg = phase == CyclePhase.ovulation
        ? AppColors.wellnessOrangeText
        : _getPhaseColor(phase);
    final Color badgeTextColor = phase == CyclePhase.ovulation
        ? AppColors.white
        : _getPhaseTextColor(phase);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 15.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.wellnessBeige.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day $selectedDay',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.r8,
                ),
                child: Text(
                  '• ${_getPhaseName(phase)}',
                  // Bullet point prefix matching mockup
                  style: AppTextStyles.labelSmall.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            hasEntry && journal != null && !journal.isEmpty
                ? journal.summaryText
                : 'No symptoms logged. Tap "+ Log today" to record how you feel.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --- Predictions Card ---
  Widget _buildPredictionsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.wellnessBeigeCardBg,
        // Warm cream background matching mockup
        borderRadius: AppRadius.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 15.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.wellnessBeige.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Predictions',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.h16,
          _buildPredictionRow(
            AppColors.phaseFollicular,
            'Next period',
            'in 20 days • Jul 20',
          ),
          const SizedBox(height: 12.0),
          _buildPredictionRow(
            AppColors.wellnessBeige,
            'Fertile window',
            'Jul 12 – Jul 17',
          ),
          const SizedBox(height: 12.0),
          _buildPredictionRow(AppColors.wellnessBeige, 'Ovulation', 'Jul 14'),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(Color dotColor, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        AppSpacing.w16,
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.w600, // Medium weight matching mockup
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.wellnessGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// --- PRIVATE WEEKDAY LABEL HELPER ---
class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.wellnessGray.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// --- LOG TODAY BOTTOM SHEET EDITOR ---
class _LogTodayBottomSheet extends StatefulWidget {
  final DayJournal initialJournal;

  const _LogTodayBottomSheet({required this.initialJournal});

  @override
  State<_LogTodayBottomSheet> createState() => _LogTodayBottomSheetState();
}

class _LogTodayBottomSheetState extends State<_LogTodayBottomSheet> {
  final Set<String> _selectedMoods = {};
  final Set<String> _selectedSymptoms = {};
  double _energy = 0.6;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedMoods.addAll(widget.initialJournal.moods);
    _selectedSymptoms.addAll(widget.initialJournal.symptoms);
    _energy = widget.initialJournal.energy;
    _notesController = TextEditingController(text: widget.initialJournal.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleMood(String mood) {
    setState(() {
      if (_selectedMoods.contains(mood)) {
        _selectedMoods.remove(mood);
      } else {
        _selectedMoods.add(mood);
      }
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Moods items
    final moods = [
      {'name': 'Calm', 'icon': Icons.sentiment_satisfied_alt_rounded},
      {'name': 'Happy', 'icon': Icons.sentiment_very_satisfied_rounded},
      {'name': 'Tired', 'icon': Icons.sentiment_neutral_rounded},
      {'name': 'Sensitive', 'icon': Icons.sentiment_dissatisfied_rounded},
      {'name': 'Strong', 'icon': Icons.fitness_center_rounded},
    ];

    // Symptoms items with icons from assets/icons/symptoms/
    final symptoms = [
      {
        'name': 'Cramps',
        'asset': 'assets/icons/symptoms/cramps.png',
        'icon': Icons.self_improvement_rounded,
      },
      {
        'name': 'Low mood',
        'asset': 'assets/icons/symptoms/low_mood.png',
        'icon': Icons.accessibility_new_rounded,
      },
      {
        'name': 'Energized',
        'asset': 'assets/icons/symptoms/energized.png',
        'icon': Icons.directions_run_rounded,
      },
      {
        'name': 'Fatigue',
        'asset': 'assets/icons/symptoms/fatigue.png',
        'icon': Icons.airline_seat_flat_rounded,
      },
      {
        'name': 'Anxious',
        'asset': 'assets/icons/symptoms/anxious.png',
        'icon': Icons.psychology_rounded,
      },
      {
        'name': 'Bloating',
        'asset': 'assets/icons/symptoms/bloating.png',
        'icon': Icons.accessibility_rounded,
      },
      {
        'name': 'Headache',
        'asset': 'assets/icons/symptoms/headache.svg',
        'icon': Icons.personal_injury_rounded,
      },
      {
        'name': 'Tender',
        'asset': 'assets/icons/symptoms/tender.png',
        'icon': Icons.health_and_safety_rounded,
      },
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0.0,
        AppSpacing.l,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Log today + close X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log today',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: AppColors.wellnessBrown.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.wellnessBrown,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // MOOD SECTION
            Text(
              'Mood',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 10.0),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 2.5,
              ),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final item = moods[index];
                final name = item['name'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedMoods.contains(name);

                return GestureDetector(
                  onTap: () => _toggleMood(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.wellnessBrown
                          : AppColors.white,
                      borderRadius: AppRadius.r12,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.wellnessBrown
                            : AppColors.wellnessBeige.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.wellnessBrown,
                          size: 16,
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.wellnessBrown,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                              height: 1.4,
                              letterSpacing: -0.06,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24.0),

            // SYMPTOMS SECTION
            Text(
              'Symptoms',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 10.0),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 2.5,
              ),
              itemCount: symptoms.length,
              itemBuilder: (context, index) {
                final item = symptoms[index];
                final name = item['name'] as String;
                final asset = item['asset'] as String;
                final fallbackIcon = item['icon'] as IconData;
                final isSelected = _selectedSymptoms.contains(name);

                return GestureDetector(
                  onTap: () => _toggleSymptom(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.wellnessBrown
                          : AppColors.white,
                      borderRadius: AppRadius.r12,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.wellnessBrown
                            : AppColors.wellnessBeige.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSymptomIcon(asset, fallbackIcon, isSelected),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.wellnessBrown,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                              height: 1.4,
                              letterSpacing: -0.06,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24.0),

            // ENERGY SECTION (SLIDER)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Energy',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  TextSpan(
                    text: ' · ',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.wellnessBrown.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 16.0,
                    ),
                  ),
                  TextSpan(
                    text: '${(_energy * 100).toInt()}%',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: double.infinity,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.wellnessPinkAccent,
                  inactiveTrackColor: AppColors.wellnessBeigeCardBg,
                  trackHeight: 12.0,
                  trackShape: const _PillSliderTrackShape(),
                  thumbShape: const _PinkRingThumbShape(
                    enabledThumbRadius: 9.0,
                    ringColor: AppColors.wellnessPinkAccent,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                ),
                child: Slider(
                  value: _energy,
                  onChanged: (val) {
                    setState(() {
                      _energy = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // NOTES SECTION
            Text(
              'Notes',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            AppSpacing.h8,
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.wellnessBrown,
              ),
              decoration: InputDecoration(
                hintText: 'A few words about today...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.wellnessGray.withValues(alpha: 0.6),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.m),
                filled: true,
                fillColor: AppColors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.r16,
                  borderSide: const BorderSide(
                    color: AppColors.wellnessBrown,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.r16,
                  borderSide: BorderSide(
                    color: AppColors.wellnessBeige.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
              ),
            ),
            AppSpacing.h32,

            // SAVE BUTTON
            GestureDetector(
              onTap: () {
                final journal = DayJournal(
                  moods: _selectedMoods.toList(),
                  symptoms: _selectedSymptoms.toList(),
                  energy: _energy,
                  notes: _notesController.text,
                );
                Navigator.pop(context, journal);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.wellnessBrown,
                  borderRadius: AppRadius.rCircular,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                      blurRadius: 15.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Save entry',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            AppSpacing.h16,
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomIcon(
    String assetPath,
    IconData fallbackIcon,
    bool isSelected,
  ) {
    final color = isSelected ? AppColors.white : AppColors.wellnessBrown;

    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(fallbackIcon, size: 18, color: color),
        errorBuilder: (_, __, ___) =>
            Icon(fallbackIcon, size: 18, color: color),
      );
    } else {
      return Image.asset(
        assetPath,
        width: 18,
        height: 18,
        color: isSelected ? AppColors.white : null,
        errorBuilder: (_, __, ___) =>
            Icon(fallbackIcon, size: 18, color: color),
      );
    }
  }
}

class _PinkRingThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final Color ringColor;

  const _PinkRingThumbShape({
    this.enabledThumbRadius = 9.0,
    required this.ringColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: enabledThumbRadius));
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.12),
      2.0,
      true,
    );

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    final Paint strokePaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, enabledThumbRadius, strokePaint);
  }
}

class _PillSliderTrackShape extends SliderTrackShape {
  const _PillSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 12.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? const Color(0xFFF6ECE1);
    context.canvas.drawRect(trackRect, inactivePaint);

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? const Color(0xFFEE8AA4);

    final double activeWidth = (thumbCenter.dx - trackRect.left).clamp(
      0.0,
      trackRect.width,
    );
    if (activeWidth > 0) {
      final Rect activeRect = Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        activeWidth,
        trackRect.height,
      );
      context.canvas.drawRect(activeRect, activePaint);
    }
  }
}
