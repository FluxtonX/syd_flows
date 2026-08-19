import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FirstPeriodStep extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const FirstPeriodStep({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<FirstPeriodStep> createState() => _FirstPeriodStepState();
}

class _FirstPeriodStepState extends State<FirstPeriodStep> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<String> _getMonthNames() => [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthNames()[_focusedMonth.month - 1];
    final year = _focusedMonth.year;

    // Calculate days of the month
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    // Day of the week the month starts on (0 = Monday, 6 = Sunday in Dart, but we want 0 = Sunday, 6 = Saturday)
    // firstDayOfMonth.weekday is 1 (Mon) to 7 (Sun)
    final int startWeekdayOffset = (firstDayOfMonth.weekday % 7);

    final totalDaysInMonth = lastDayOfMonth.day;
    final totalDaysInPrevMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      0,
    ).day;

    final List<Widget> dayWidgets = [];

    // Weekday names Su Mo Tu We Th Fr Sa
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.wellnessGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Previous month days (faded)
    for (int i = startWeekdayOffset - 1; i >= 0; i--) {
      final dayNum = totalDaysInPrevMonth - i;
      final prevDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
        dayNum,
      );
      final isSelected =
          prevDate.year == widget.selectedDate.year &&
          prevDate.month == widget.selectedDate.month &&
          prevDate.day == widget.selectedDate.day;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );
            });
            widget.onDateSelected(prevDate);
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.wellnessBrown
                    : AppColors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                dayNum.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.wellnessGray.withValues(alpha: 0.35),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Current month days
    for (int day = 1; day <= totalDaysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected =
          date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month &&
          date.day == widget.selectedDate.day;

      dayWidgets.add(
        GestureDetector(
          onTap: () => widget.onDateSelected(date),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.wellnessBrown
                    : AppColors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                day.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.white : AppColors.wellnessBrown,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Next month days (faded) to fill grid (6 rows = 42 slots max)
    final int targetGridCount = dayWidgets.length > 35 ? 42 : 35;
    final int remainingSlots = targetGridCount - dayWidgets.length;
    for (int day = 1; day <= remainingSlots; day++) {
      final nextDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        day,
      );
      final isSelected =
          nextDate.year == widget.selectedDate.year &&
          nextDate.month == widget.selectedDate.month &&
          nextDate.day == widget.selectedDate.day;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );
            });
            widget.onDateSelected(nextDate);
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.wellnessBrown
                    : AppColors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                day.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.wellnessGray.withValues(alpha: 0.35),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.r24,
        border: Border.all(
          color: AppColors.wellnessBeige.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.04),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: month selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.wellnessBrown,
                  size: 24.0,
                ),
              ),
              Text(
                '$monthName $year',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.wellnessBrown,
                  size: 24.0,
                ),
              ),
            ],
          ),
          AppSpacing.h16,

          // Calendar Grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.s,
            crossAxisSpacing: AppSpacing.xs,
            children: dayWidgets,
          ),
        ],
      ),
    );
  }
}
