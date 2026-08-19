import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../viewmodels/cycle_view_model.dart';
import '../widgets/cycle_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/export_service.dart';
import '../../data/models/cycle_types.dart';
import '../../domain/cycle_calculator.dart';

// CyclePhase and DayJournal are now imported from cycle_types.dart

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

  // Legacy: computes period start day from month entries (fallback only)
  int _getPeriodStartDay(Map<int, DayJournal> entries) {
    // Check for explicit period start first
    final periodStartDays =
        entries.entries
            .where((e) => e.value.isPeriodStart)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (periodStartDays.isNotEmpty) return periodStartDays.last;

    // Fall back to flow days
    final flowDays =
        entries.entries
            .where((e) => e.value.flow != null && e.value.flow!.isNotEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (flowDays.isNotEmpty) {
      int latestStart = flowDays.last;
      for (int i = flowDays.length - 1; i > 0; i--) {
        if (flowDays[i] - flowDays[i - 1] == 1) {
          latestStart = flowDays[i - 1];
        } else {
          break;
        }
      }
      return latestStart;
    }
    return 1;
  }

  /// Returns the phase for [day] in the current calendar month using CycleCalculator.
  CyclePhase _getDayPhase(int day) {
    final date = DateTime(
      _viewModel.currentYear,
      _viewModel.currentMonth,
      day,
    );
    final cycleNotifier = CycleProvider.ofNullable(context);
    if (cycleNotifier != null) {
      return cycleNotifier.phaseForCalendarDate(date);
    }

    return CycleCalculator.phaseForDate(
      date: date,
      anchor: DateTime.now(),
      cycleLength: 28,
      periodLength: 5,
    );
  }

  Widget _buildFlowIndicator(String flow, bool isSelected) {
    const spottingSelectedColor = Color(0xFFD32F2F); // Active Red Accent
    final dropColor = isSelected ? AppColors.wellnessBrown : AppColors.white;
    final dropShadows = isSelected
        ? null
        : const [
            Shadow(
              color: Colors.black38,
              blurRadius: 2.0,
              offset: Offset(0, 0.5),
            ),
          ];

    switch (flow.toLowerCase()) {
      case 'spotting':
        final dotColor = isSelected ? spottingSelectedColor : AppColors.white;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? null
                      : const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 1.5,
                            offset: Offset(0, 0.5),
                          ),
                        ],
                ),
              ),
            ),
          ),
        );
      case 'light':
        return Icon(
          Icons.water_drop_rounded,
          size: 5.5,
          color: dropColor,
          shadows: dropShadows,
        );
      case 'medium':
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_rounded,
              size: 7.5,
              color: dropColor,
              shadows: dropShadows,
            ),
            Icon(
              Icons.water_drop_rounded,
              size: 7.5,
              color: dropColor,
              shadows: dropShadows,
            ),
          ],
        );
      case 'heavy':
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_rounded,
              size: 9.5,
              color: dropColor,
              shadows: dropShadows,
            ),
            Icon(
              Icons.water_drop_rounded,
              size: 9.5,
              color: dropColor,
              shadows: dropShadows,
            ),
            Icon(
              Icons.water_drop_rounded,
              size: 9.5,
              color: dropColor,
              shadows: dropShadows,
            ),
          ],
        );
      default:
        return Icon(
          Icons.water_drop_rounded,
          size: 7.0,
          color: dropColor,
          shadows: dropShadows,
        );
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
      case CyclePhase.unknown:
        return AppColors.phaseFollicular;
    }
  }

  Color _getPhaseTextColor(CyclePhase phase) {
    return AppColors.white;
  }

  String _getPhaseName(CyclePhase phase) {
    return phase.shortLabel;
  }

  void _showLogSheet({int? targetDay}) async {
    final dayToLog = targetDay ?? _viewModel.selectedDay;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      _viewModel.currentYear,
      _viewModel.currentMonth,
      dayToLog,
    );

    if (targetDate.isAfter(todayDate)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot log future dates.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.wellnessBrown,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _viewModel.setSelectedDay(dayToLog);

    final initialJournal =
        _viewModel.journalEntries[dayToLog] ??
        DayJournal(moods: [], symptoms: [], energy: 0.6, notes: '');

    final isToday = targetDate.isAtSameMomentAs(todayDate);
    final monthName = _viewModel.shortMonthName;
    final title = isToday ? 'Log today' : 'Log for $monthName $dayToLog';

    final result = await showModalBottomSheet<DayJournal>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => _LogTodayBottomSheet(
        initialJournal: initialJournal,
        title: title,
      ),
    );

    if (result != null) {
      _viewModel.saveLog(dayToLog, result);
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

        final periodStartDay = _getPeriodStartDay(journalEntries);

        final int daysInMonth = DateTime(
          _viewModel.currentYear,
          _viewModel.currentMonth + 1,
          0,
        ).day;
        final int firstWeekday = DateTime(
          _viewModel.currentYear,
          _viewModel.currentMonth,
          1,
        ).weekday;
        final int emptySlots = firstWeekday % 7; // Sunday = 0, Monday = 1, ...

        final List<int> calendarDays = [
          ...List.filled(emptySlots, 0),
          ...List.generate(daysInMonth, (index) => index + 1),
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
                        _buildCalendarCard(
                          calendarDays,
                          selectedDay,
                          periodStartDay,
                        ),
                        AppSpacing.h24,
                        _buildSelectedDayDetailCard(
                          selectedDay,
                          currentPhase,
                          hasEntry,
                          currentJournal,
                        ),
                        AppSpacing.h24,
                        _buildPredictionsCard(periodStartDay),
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

  void _showExportDialog() {
    ExportDateRange selectedRange = ExportDateRange.allTime;
    bool isExporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Drag handle
                    Center(
                      child: Container(
                        width: 36.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Title & Description
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: AppColors.wellnessBrown.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            color: AppColors.wellnessBrown,
                            size: 22.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Cycle Report',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.wellnessBrown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              Text(
                                'Download & share your cycle health summary for your doctor or personal records.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.wellnessGray,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Select Date Range Label
                    Text(
                      'SELECT REPORT DATE RANGE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.wellnessGray,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Date Range Options List
                    ...ExportDateRange.values.map((range) {
                      final isSelected = selectedRange == range;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedRange = range;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.wellnessBrown.withValues(alpha: 0.06)
                                : AppColors.white,
                            borderRadius: AppRadius.r16,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.wellnessBrown
                                  : AppColors.wellnessBeige.withValues(alpha: 0.3),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? AppColors.wellnessBrown
                                    : AppColors.wellnessBeige,
                                size: 20.0,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      range.label,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.wellnessBrown,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      range.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.wellnessGray,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16.0),

                    // Export & Share Button
                    SizedBox(
                      height: 48.0,
                      child: ElevatedButton.icon(
                        onPressed: isExporting
                            ? null
                            : () async {
                                final uid = AuthService.instance.currentUser?.uid;
                                if (uid == null) {
                                  Navigator.pop(context);
                                  return;
                                }

                                setModalState(() => isExporting = true);

                                try {
                                  final notifier = CycleProvider.of(this.context);
                                  final result =
                                      await ExportService.instance.exportCycleLogsCsv(
                                    uid: uid,
                                    settings: notifier.settings,
                                    range: selectedRange,
                                    shareFile: true,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Exported ${result.recordCount} cycle records (${selectedRange.label}) to CSV 📄',
                                        ),
                                        backgroundColor: AppColors.wellnessBrown,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isExporting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Export failed: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.ios_share_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                        label: Text(
                          isExporting
                              ? 'Generating Report...'
                              : 'Download & Share Report',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wellnessBrown,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.r16,
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
      },
    );
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
        Row(
          children: [
            // Export Icon Button
            GestureDetector(
              onTap: _showExportDialog,
              child: Container(
                height: 40.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.r8,
                  border: Border.all(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.wellnessBrown,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Export',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            // + Log button matching exact Figma properties
            GestureDetector(
              onTap: () => _showLogSheet(),
              child: Container(
                height: 40.0,
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.logTodayGradient,
                  ),
                  borderRadius: AppRadius.r8,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF08AAE).withValues(alpha: 0.32),
                      offset: const Offset(0, 12),
                      blurRadius: 40.0,
                      spreadRadius: -8.0,
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
                    const SizedBox(width: 4.0),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final isToday =
                            _viewModel.currentYear == now.year &&
                            _viewModel.currentMonth == now.month &&
                            _viewModel.selectedDay == now.day;
                        return Text(
                          isToday ? 'Log today' : 'Log Day ${_viewModel.selectedDay}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                        );
                      },
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

  // --- Calendar Card ---
  Widget _buildCalendarCard(
    List<int> calendarDays,
    int selectedDay,
    int periodStartDay,
  ) {
    final journalEntries = _viewModel.journalEntries;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            _viewModel.nextMonth();
          } else if (details.primaryVelocity! > 200) {
            _viewModel.previousMonth();
          }
        }
      },
      child: Container(
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
            // Month navigation selector: < Month Year >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    _viewModel.previousMonth();
                  },
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.wellnessGray,
                    size: 24,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    '${_viewModel.monthName} ${_viewModel.currentYear}',
                    key: ValueKey(
                      '${_viewModel.monthName}-${_viewModel.currentYear}',
                    ),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _viewModel.nextMonth();
                  },
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
            // Days Grid with Smooth Animated Switcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: GridView.builder(
                key: ValueKey(
                  '${_viewModel.currentYear}-${_viewModel.currentMonth}',
                ),
                padding: EdgeInsets.zero,
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
                  final journal = journalEntries[day];
                  final flow = journal?.flow;

                  return GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      final todayDate = DateTime(now.year, now.month, now.day);
                      final cellDate = DateTime(
                        _viewModel.currentYear,
                        _viewModel.currentMonth,
                        day,
                      );

                      if (cellDate.isAtSameMomentAs(todayDate)) {
                        _viewModel.setSelectedDay(day);
                        _showLogSheet(targetDay: day);
                      } else if (cellDate.isAfter(todayDate)) {
                        // Short message for future dates as requested
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot log future dates.'),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppColors.wellnessBrown,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // Automatically revert selection & month back to today's date
                        _viewModel.resetToToday();
                      } else {
                        // Past date — select day and open log sheet to view/edit
                        final wasAlreadySelected = _viewModel.selectedDay == day;
                        _viewModel.setSelectedDay(day);
                        if (wasAlreadySelected) {
                          _showLogSheet(targetDay: day);
                        }
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white
                            : _getPhaseColor(phase),
                        borderRadius: BorderRadius.circular(8.0),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.wellnessBrown,
                                width: 2.0,
                              )
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
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
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            if (flow != null && flow.isNotEmpty)
                              _buildFlowIndicator(flow, isSelected),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                : 'No log data recorded for Day $selectedDay.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12.0),
          GestureDetector(
            onTap: () => _showLogSheet(targetDay: selectedDay),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.wellnessBrown.withValues(alpha: 0.08),
                borderRadius: AppRadius.r8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasEntry && journal != null && !journal.isEmpty
                        ? Icons.edit_rounded
                        : Icons.add_rounded,
                    size: 14.0,
                    color: AppColors.wellnessBrown,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    hasEntry && journal != null && !journal.isEmpty
                        ? 'Edit log entry'
                        : 'Log for Day $selectedDay',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.wellnessBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Predictions Card ---
  Widget _buildPredictionsCard(int periodStartDay) {
    // Use CycleStateNotifier for accurate predictions
    final cycleNotifier = CycleProvider.ofNullable(context);
    final predictions = cycleNotifier?.currentStatus.predictions;

    String nextPeriodText;
    String fertileText;
    String ovulationText;

    if (predictions != null) {
      // Format using CycleStateNotifier predictions
      final daysUntil = predictions.daysUntilNextPeriod;
      final np = predictions.nextPeriodStart;
      final npFormatted = '${_shortMonth(np.month)} ${np.day}';
      nextPeriodText = daysUntil > 0
          ? 'in $daysUntil days • $npFormatted'
          : (daysUntil == 0 ? 'Today • $npFormatted' : npFormatted);

      final fs = predictions.fertileWindowStart;
      final fe = predictions.fertileWindowEnd;
      fertileText =
          '${_shortMonth(fs.month)} ${fs.day} – ${_shortMonth(fe.month)} ${fe.day}';

      final ov = predictions.ovulationDate;
      ovulationText = '${_shortMonth(ov.month)} ${ov.day}';
    } else {
      // Fallback to legacy month-scoped calculation
      final monthShort = _viewModel.shortMonthName;
      final nextMonthShort = _viewModel.nextShortMonthName;
      final daysInMonth = DateTime(
        _viewModel.currentYear,
        _viewModel.currentMonth + 1,
        0,
      ).day;

      final rawNextDay = periodStartDay + 28;
      final isNextMonth = rawNextDay > daysInMonth;
      final nextPeriodDay = isNextMonth
          ? (rawNextDay - daysInMonth)
          : rawNextDay;
      final targetMonthName = isNextMonth ? nextMonthShort : monthShort;
      final todayDay = DateTime.now().day;
      final daysUntilNextPeriod = isNextMonth
          ? (daysInMonth - todayDay + nextPeriodDay)
          : (nextPeriodDay - todayDay);
      nextPeriodText = daysUntilNextPeriod > 0
          ? 'in $daysUntilNextPeriod days • $targetMonthName $nextPeriodDay'
          : '$targetMonthName $nextPeriodDay';

      final rawFertileStart = periodStartDay + 11;
      final fertileStartDay = rawFertileStart > daysInMonth
          ? rawFertileStart - daysInMonth
          : rawFertileStart;
      final fertileStartMonth = rawFertileStart > daysInMonth
          ? nextMonthShort
          : monthShort;
      final rawFertileEnd = periodStartDay + 16;
      final fertileEndDay = rawFertileEnd > daysInMonth
          ? rawFertileEnd - daysInMonth
          : rawFertileEnd;
      final fertileEndMonth = rawFertileEnd > daysInMonth
          ? nextMonthShort
          : monthShort;
      fertileText =
          '$fertileStartMonth $fertileStartDay – $fertileEndMonth $fertileEndDay';

      final rawOvulationDay = periodStartDay + 13;
      final ovulationDay = rawOvulationDay > daysInMonth
          ? rawOvulationDay - daysInMonth
          : rawOvulationDay;
      final ovulationMonth = rawOvulationDay > daysInMonth
          ? nextMonthShort
          : monthShort;
      ovulationText = '$ovulationMonth $ovulationDay';
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.wellnessBeigeCardBg,
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
            nextPeriodText,
          ),
          const SizedBox(height: 12.0),
          _buildPredictionRow(
            AppColors.wellnessBeige,
            'Fertile window',
            fertileText,
          ),
          const SizedBox(height: 12.0),
          _buildPredictionRow(
            AppColors.wellnessBeige,
            'Ovulation',
            ovulationText,
          ),
        ],
      ),
    );
  }

  static const List<String> _shortMonths = [
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

  static String _shortMonth(int month) =>
      _shortMonths[(month - 1).clamp(0, 11)];

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
  final String title;

  const _LogTodayBottomSheet({
    required this.initialJournal,
    this.title = 'Log today',
  });

  @override
  State<_LogTodayBottomSheet> createState() => _LogTodayBottomSheetState();
}

class _LogTodayBottomSheetState extends State<_LogTodayBottomSheet> {
  String? _selectedFlow;
  final Set<String> _selectedMoods = {};
  final Set<String> _selectedSymptoms = {};
  double _energy = 0.6;
  bool _isPeriodStart = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedFlow = widget.initialJournal.flow;
    _selectedMoods.addAll(widget.initialJournal.moods);
    _selectedSymptoms.addAll(widget.initialJournal.symptoms);
    _energy = widget.initialJournal.energy;
    _isPeriodStart = widget.initialJournal.isPeriodStart;
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

  Widget _buildFlowChip(String key, String labelText) {
    final isSelected = _selectedFlow == key;
    final contentColor = isSelected ? AppColors.white : AppColors.wellnessBrown;
    final activeIconColor = contentColor;

    Widget iconWidget;
    switch (key.toLowerCase()) {
      case 'spotting':
        iconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              width: 3.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: activeIconColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
        break;
      case 'light':
        iconWidget = Icon(
          Icons.water_drop_rounded,
          size: 11.0,
          color: activeIconColor,
        );
        break;
      case 'medium':
        iconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded, size: 12.0, color: activeIconColor),
            Icon(Icons.water_drop_rounded, size: 12.0, color: activeIconColor),
          ],
        );
        break;
      case 'heavy':
        iconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded, size: 13.0, color: activeIconColor),
            Icon(Icons.water_drop_rounded, size: 13.0, color: activeIconColor),
            Icon(Icons.water_drop_rounded, size: 13.0, color: activeIconColor),
          ],
        );
        break;
      default:
        iconWidget = const SizedBox();
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFlow = isSelected ? null : key;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.wellnessBrown : AppColors.white,
            borderRadius: AppRadius.r12,
            border: Border.all(
              color: isSelected
                  ? AppColors.wellnessBrown
                  : AppColors.wellnessBeige.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 14.0, child: Center(child: iconWidget)),
              const SizedBox(height: 3.0),
              Text(
                labelText,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  widget.title,
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

            // FLOW SECTION
            Text(
              'Flow',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _buildFlowChip('spotting', 'Spotting'),
                _buildFlowChip('light', 'Light'),
                _buildFlowChip('medium', 'Medium'),
                _buildFlowChip('heavy', 'Heavy'),
              ],
            ),
            const SizedBox(height: 10.0),
            // Period Started Today toggle (Sleek Inline Toggle Card)
            GestureDetector(
              onTap: () => setState(() => _isPeriodStart = !_isPeriodStart),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: _isPeriodStart
                      ? AppColors.phaseMenstrual.withValues(alpha: 0.08)
                      : AppColors.white,
                  borderRadius: AppRadius.r12,
                  border: Border.all(
                    color: _isPeriodStart
                        ? AppColors.phaseMenstrual
                        : AppColors.wellnessBeige.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: _isPeriodStart
                          ? AppColors.phaseMenstrual
                          : AppColors.wellnessBeige,
                      size: 18,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Period started today',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.wellnessBrown,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                            ),
                          ),
                          if (_isPeriodStart)
                            Text(
                              'New cycle begins',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.phaseMenstrual,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: _isPeriodStart,
                        onChanged: (val) => setState(() => _isPeriodStart = val),
                        activeTrackColor: AppColors.phaseMenstrual,
                      ),
                    ),
                  ],
                ),
              ),
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
              padding: EdgeInsets.zero,
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
            const SizedBox(height: 16.0),

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
              padding: EdgeInsets.zero,
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
            const SizedBox(height: 16.0),

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
            const SizedBox(height: 16.0),

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
                  flow: _selectedFlow,
                  moods: _selectedMoods.toList(),
                  symptoms: _selectedSymptoms.toList(),
                  energy: _energy,
                  notes: _notesController.text,
                  isPeriodStart: _isPeriodStart,
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
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: 18, color: color),
      );
    } else {
      return Image.asset(
        assetPath,
        width: 18,
        height: 18,
        color: isSelected ? AppColors.white : null,
        errorBuilder: (context, error, stackTrace) =>
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
