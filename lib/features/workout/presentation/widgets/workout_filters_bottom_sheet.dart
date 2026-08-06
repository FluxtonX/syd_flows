import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class WorkoutFiltersBottomSheet extends StatefulWidget {
  final List<String> initialDifficulties;
  final List<String> initialTypes;
  final List<String> initialEquipment;
  final double initialMaxDuration;

  const WorkoutFiltersBottomSheet({
    super.key,
    required this.initialDifficulties,
    required this.initialTypes,
    required this.initialEquipment,
    required this.initialMaxDuration,
  });

  @override
  State<WorkoutFiltersBottomSheet> createState() => _WorkoutFiltersBottomSheetState();
}

class _WorkoutFiltersBottomSheetState extends State<WorkoutFiltersBottomSheet> {
  late List<String> _selectedPhaseTypes;
  late List<String> _selectedDifficulties;
  late List<String> _selectedWorkoutTypes;
  late List<String> _selectedEquipment;
  late double _maxDuration;

  final List<String> _phaseTypes = ['Menstrual', 'Follicular', 'Ovulation', 'Luteal'];
  final List<String> _difficulties = ['Gentle', 'Moderate', 'Strong'];
  final List<String> _workoutTypes = ['Yoga', 'Pilates', 'Strength', 'Mobility'];
  final List<String> _equipment = [
    'Mat',
    'Light Dumbbells',
    'Pilates Ball',
    'Heavy Dumbbells',
    'Pilates Circle',
    'Pillow',
    'Yoga Blocks',
    'Foam Roller',
    'Booty Bands',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPhaseTypes = [];
    _selectedDifficulties = List<String>.from(widget.initialDifficulties);
    _selectedWorkoutTypes = List<String>.from(widget.initialTypes);
    _selectedEquipment = List<String>.from(widget.initialEquipment);
    _maxDuration = widget.initialMaxDuration;
  }

  int _calculateMatchCount() {
    final allWorkouts = [
      {'difficulty': 'Gentle', 'type': 'Yoga', 'equipment': 'Mat', 'duration': 22},
      {'difficulty': 'Moderate', 'type': 'Pilates', 'equipment': 'Mat', 'duration': 28},
      {'difficulty': 'Strong', 'type': 'Strength', 'equipment': 'Dumbbells', 'duration': 32},
      {'difficulty': 'Gentle', 'type': 'Mobility', 'equipment': 'Mat', 'duration': 18},
      {'difficulty': 'Moderate', 'type': 'Barre', 'equipment': 'Chair', 'duration': 25},
      {'difficulty': 'Gentle', 'type': 'Cardio', 'equipment': 'None', 'duration': 30},
    ];

    return allWorkouts.where((workout) {
      if (_selectedDifficulties.isNotEmpty && !_selectedDifficulties.contains(workout['difficulty'])) {
        return false;
      }
      if (_selectedWorkoutTypes.isNotEmpty && !_selectedWorkoutTypes.contains(workout['type'])) {
        return false;
      }
      if (workout['duration'] as int > _maxDuration) {
        return false;
      }
      return true;
    }).length;
  }

  void _resetFilters() {
    setState(() {
      _selectedPhaseTypes.clear();
      _selectedDifficulties.clear();
      _selectedWorkoutTypes.clear();
      _selectedEquipment.clear();
      _maxDuration = 45.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchCount = _calculateMatchCount();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAF4ED),
            Color(0xFFFBF0E8),
            Color(0xFFFFD4E2),
            Color(0xFFFFBCCF),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.wellnessBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
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
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.h24,

            // Section 1: Type (Phase Types)
            _buildSectionHeader('Type'),
            const SizedBox(height: 10.0),
            _buildFilterChips(_phaseTypes, _selectedPhaseTypes),
            AppSpacing.h24,

            // Section 2: Difficulty
            _buildSectionHeader('Difficulty'),
            const SizedBox(height: 10.0),
            _buildFilterChips(_difficulties, _selectedDifficulties),
            AppSpacing.h24,

            // Section 3: Type (Workout Types)
            _buildSectionHeader('Type'),
            const SizedBox(height: 10.0),
            _buildFilterChips(_workoutTypes, _selectedWorkoutTypes),
            AppSpacing.h24,

            // Section 4: Equipment
            _buildSectionHeader('Equipment'),
            const SizedBox(height: 10.0),
            _buildFilterChips(_equipment, _selectedEquipment),
            AppSpacing.h24,

            // Max Duration Section (Inline Title + Pill Slider)
            Text(
              'Max duration · ${_maxDuration.toInt()} min',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
            ),
            const SizedBox(height: 4.0),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackShape: const _PillSliderTrackShape(),
                thumbShape: const _PinkRingThumbShape(
                  enabledThumbRadius: 9.0,
                  ringColor: AppColors.wellnessBrown,
                ),
                tickMarkShape: SliderTickMarkShape.noTickMark,
                activeTrackColor: AppColors.wellnessBrown,
                inactiveTrackColor: const Color(0xFFF7EFE9),
                trackHeight: 14.0,
              ),
              child: Slider(
                value: _maxDuration,
                min: 15.0,
                max: 60.0,
                onChanged: (val) {
                  setState(() {
                    _maxDuration = val;
                  });
                },
              ),
            ),
            AppSpacing.h32,

            // Bottom Actions (Reset + Show X)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _resetFilters,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: const Color(0xFFFFD8E5),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.wellnessBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.w16,
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {
                        'difficulties': _selectedDifficulties,
                        'types': _selectedWorkoutTypes,
                        'equipment': _selectedEquipment,
                        'maxDuration': _maxDuration,
                      });
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.wellnessBrown,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Show $matchCount',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.h16,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.wellnessBrown,
        fontWeight: FontWeight.bold,
        fontSize: 15.0,
      ),
    );
  }

  Widget _buildFilterChips(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedList.remove(option);
              } else {
                selectedList.add(option);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.wellnessBrown : AppColors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isSelected 
                    ? AppColors.wellnessBrown 
                    : const Color(0xFFFFD8E5), // Pink stroke from Figma
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.wellnessBrown,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6.0),
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
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
    final double trackHeight = sliderTheme.trackHeight ?? 14.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
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
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor ?? AppColors.wellnessBrown;
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? const Color(0xFFF7EFE9);

    // Inactive track (right) - flat rectangular line
    context.canvas.drawRect(
      trackRect,
      inactivePaint,
    );

    // Active track (left) - flat rectangular line
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRect(
      activeRect,
      activePaint,
    );
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

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: enabledThumbRadius));
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.2), 3.0, true);

    canvas.drawCircle(center, enabledThumbRadius, fillPaint);
    canvas.drawCircle(center, enabledThumbRadius, ringPaint);
  }
}
