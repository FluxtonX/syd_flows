import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../data/models/workout_model.dart';
import '../widgets/workout_filters_bottom_sheet.dart';
import 'workout_detail_screen.dart';

export '../../data/models/workout_model.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'For you';

  // Filter states
  List<String> _selectedDifficulties = [];
  List<String> _selectedTypes = [];
  List<String> _selectedEquipment = [];
  double _maxDuration = 45.0;

  final List<Workout> _allWorkouts = const [
    Workout(
      id: '1',
      title: 'Ultimate 10 Minute Yoga Stretch for Stress Relief',
      category: 'YOGA',
      duration: 10,
      difficulty: 'Gentle',
      type: 'Yoga',
      equipment: 'Mat',
      imagePath: AppAssets.sunriseFlow,
      videoUrl: 'https://www.youtube.com/watch?v=Zle59BeF-fQ&t=16s',
      videoId: 'Zle59BeF-fQ',
    ),
    Workout(
      id: '2',
      title: '10 Minute Pilates Booty Burn - BEGINNER FRIENDLY',
      category: 'PILATES',
      duration: 10,
      difficulty: 'Moderate',
      type: 'Pilates',
      equipment: 'Mat',
      imagePath: AppAssets.pilatesCore,
      videoUrl: 'https://www.youtube.com/watch?v=yzmpVPAmTTE',
      videoId: 'yzmpVPAmTTE',
    ),
    Workout(
      id: '3',
      title: 'Feel Good Yoga Stretch - 15 mins',
      category: 'YOGA',
      duration: 15,
      difficulty: 'Gentle',
      type: 'Yoga',
      equipment: 'Mat',
      imagePath: AppAssets.restorativeStretch,
      videoUrl: 'https://www.youtube.com/watch?v=jhbPBphMFuk',
      videoId: 'jhbPBphMFuk',
    ),
    Workout(
      id: '4',
      title: 'Power Strength HIIT',
      category: 'STRENGTH',
      duration: 32,
      difficulty: 'Strong',
      type: 'Strength',
      equipment: 'Dumbbells',
      imagePath: AppAssets.powerStrength,
      videoUrl: null,
      videoId: null,
    ),
    Workout(
      id: '5',
      title: 'Barre Sculpt Lite',
      category: 'BARRE',
      duration: 25,
      difficulty: 'Moderate',
      type: 'Barre',
      equipment: 'Chair',
      imagePath: AppAssets.barreSculpt,
      videoUrl: null,
      videoId: null,
    ),
    Workout(
      id: '6',
      title: 'Breathe Outdoor',
      category: 'CARDIO',
      duration: 30,
      difficulty: 'Gentle',
      type: 'Cardio',
      equipment: 'None',
      imagePath: AppAssets.breathOutdoor,
      videoUrl: null,
      videoId: null,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Workout> _getFilteredWorkouts() {
    return _allWorkouts.where((workout) {
      // 0. Only show workouts that have a valid real video link!
      if (!workout.hasVideo) return false;

      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = workout.title.toLowerCase().contains(query);
        final matchesCategory = workout.category.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCategory) return false;
      }


      // 2. Horizontal Scroll Categories
      if (_selectedCategory != 'For you') {
        if (workout.type.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // 3. Difficulty Filter (from Bottom Sheet)
      if (_selectedDifficulties.isNotEmpty) {
        if (!_selectedDifficulties.contains(workout.difficulty)) {
          return false;
        }
      }

      // 4. Type Filter (from Bottom Sheet)
      if (_selectedTypes.isNotEmpty) {
        if (!_selectedTypes.contains(workout.type)) {
          return false;
        }
      }

      // 5. Equipment Filter (from Bottom Sheet)
      if (_selectedEquipment.isNotEmpty) {
        if (!_selectedEquipment.contains(workout.equipment)) {
          return false;
        }
      }

      // 6. Max Duration Filter (from Bottom Sheet)
      if (workout.duration > _maxDuration) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFiltersBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutFiltersBottomSheet(
        initialDifficulties: _selectedDifficulties,
        initialTypes: _selectedTypes,
        initialEquipment: _selectedEquipment,
        initialMaxDuration: _maxDuration,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDifficulties = List<String>.from(result['difficulties'] ?? []);
        _selectedTypes = List<String>.from(result['types'] ?? []);
        _selectedEquipment = List<String>.from(result['equipment'] ?? []);
        _maxDuration = result['maxDuration'] ?? 45.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkouts = _getFilteredWorkouts();

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.h16,
              // Title and Subtitle
              Text(
                'Workouts',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Tuned to your phase, body and goals.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.wellnessGray,
                ),
              ),
              AppSpacing.h24,

              // Search Bar + Filter Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.r16,
                        border: Border.all(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.wellnessBrown,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search workouts, instructors...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.wellnessGray.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.wellnessBrown.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.w16,
                  GestureDetector(
                    onTap: _showFiltersBottomSheet,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.r16,
                        border: Border.all(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.wellnessBrown,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.h24,

              // Horizontal scrollable categories
              _buildCategoryScrollList(),
              AppSpacing.h24,

              // Workouts Count Row
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredWorkouts.length} workouts',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.wellnessGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.h16,

              // Workouts List
              Expanded(
                child: filteredWorkouts.isEmpty
                    ? _buildEmptyState()
                    : _buildListView(filteredWorkouts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryScrollList() {
    final categories = [
      'For you',
      'Yoga',
      'Pilates',
      'Strength',
      'Cardio',
      'Mobility',
      'Barre',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.wellnessBrown : AppColors.white,
                  borderRadius: AppRadius.r16,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.wellnessBrown
                        : AppColors.wellnessBrown.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 14,
                      ),
                      AppSpacing.w4,
                    ],
                    Text(
                      cat,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.wellnessBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Workout> workouts) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        return _buildListCard(workouts[index]);
      },
    );
  }

  Widget _buildListCard(Workout workout) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(workout: workout),
          ),
        );
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          borderRadius: AppRadius.r16,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.r16,
          child: Stack(
            children: [
              // 1. Full Bleed Image
              Positioned.fill(
                child: Image.asset(
                  workout.imagePath,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.0, -0.2),
                ),
              ),

              // 2. Horizontal Gradient Overlay (Darker on the right)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.black.withValues(alpha: 0.15),
                        AppColors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // 3. Text Overlay aligned to the Right half
              Positioned(
                right: 20.0,
                left: 140.0,
                top: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      workout.category,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.wellnessOrangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      workout.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: AppColors.white,
                          size: 13.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${workout.duration}m',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          workout.difficulty,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 48,
            color: AppColors.wellnessBrown.withValues(alpha: 0.3),
          ),
          AppSpacing.h16,
          Text(
            'No workouts match your filters.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Try resetting your filters or search query.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.wellnessGray.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
