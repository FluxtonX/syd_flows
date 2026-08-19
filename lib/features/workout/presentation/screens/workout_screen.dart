import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/subscription_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Workout> _getFilteredWorkouts(List<Workout> allWorkouts) {
    return allWorkouts.where((workout) {
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
        final sel = _selectedCategory.toLowerCase();
        final wType = workout.type.toLowerCase();
        final wCat = workout.category.toLowerCase();
        if (wType != sel && wCat != sel) {
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
        if (!_selectedTypes.contains(workout.type) &&
            !_selectedTypes.contains(workout.category)) {
          return false;
        }
      }

      // 5. Equipment Filter (from Bottom Sheet)
      if (_selectedEquipment.isNotEmpty) {
        if (!_selectedEquipment.contains(workout.equipment) &&
            !_selectedEquipment.contains(workout.propsUsed)) {
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
    final user = AuthService.instance.currentUser;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('videos').snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.transparent,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.wellnessBrown,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final allWorkouts = docs
            .map((doc) => Workout.fromFirestore(doc.data(), doc.id))
            .toList();

        final filteredWorkouts = _getFilteredWorkouts(allWorkouts);

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
                              hintText: 'Search workouts, categories...',
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
                    child: StreamBuilder<bool>(
                      stream: SubscriptionService.instance.streamHasPremiumAccess(),
                      builder: (context, accessSnapshot) {
                        if (filteredWorkouts.isEmpty) {
                          return _buildEmptyState(allWorkouts.isEmpty);
                        }
                        return _buildListView(
                          filteredWorkouts,
                          hasPremiumAccess: accessSnapshot.data == true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryScrollList() {
    final categories = [
      'For you',
      'Yoga',
      'Pilates',
      'Strength',
      'Mobility',
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

  Widget _buildListView(
    List<Workout> workouts, {
    required bool hasPremiumAccess,
  }) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        return _buildListCard(
          workouts[index],
          hasPremiumAccess: hasPremiumAccess,
        );
      },
    );
  }

  Widget _buildListCard(
    Workout workout, {
    required bool hasPremiumAccess,
  }) {
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
              // 1. Full Bleed Image (Support Network & Asset)
              Positioned.fill(
                child: (workout.imagePath.startsWith('http://') ||
                        workout.imagePath.startsWith('https://'))
                    ? Image.network(
                        workout.imagePath,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.0, -0.2),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.movie_creation_outlined,
                            color: AppColors.wellnessBrown,
                            size: 36,
                          ),
                        ),
                      )
                    : (workout.imagePath.isNotEmpty
                        ? Image.asset(
                            workout.imagePath,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0.0, -0.2),
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                color: AppColors.wellnessBrown,
                                size: 36,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.wellnessBrown.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: AppColors.wellnessBrown,
                              size: 36,
                            ),
                          )),
              ),

              if (workout.isPaid)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.wellnessBrown.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasPremiumAccess) ...const [
                          Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                        ],
                        const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                        Expanded(
                          child: Text(
                            workout.cyclePhase,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                            ),
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

  Widget _buildEmptyState(bool noAdminUploadsYet) {
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
            noAdminUploadsYet
                ? 'No videos uploaded yet'
                : 'No workouts match your filters',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.wellnessGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            noAdminUploadsYet
                ? 'Upload video workouts from the web admin panel.'
                : 'Try resetting your filters or search query.',
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
