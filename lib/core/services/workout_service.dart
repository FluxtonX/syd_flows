import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/workout/data/models/workout_model.dart';
import '../utils/helpers.dart';

class CompletedWorkoutRecord {
  final String id;
  final String workoutId;
  final String title;
  final int duration;
  final int calories;
  final DateTime completedAt;

  const CompletedWorkoutRecord({
    required this.id,
    required this.workoutId,
    required this.title,
    required this.duration,
    required this.calories,
    required this.completedAt,
  });

  factory CompletedWorkoutRecord.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime date = DateTime.now();
    if (map['completedAt'] is Timestamp) {
      date = (map['completedAt'] as Timestamp).toDate();
    } else if (map['completedAt'] is String) {
      date = DateTime.tryParse(map['completedAt']) ?? DateTime.now();
    }

    return CompletedWorkoutRecord(
      id: docId,
      workoutId: (map['workoutId'] as String?) ?? docId,
      title: (map['title'] as String?) ?? 'Workout Session',
      duration: (map['duration'] as num?)?.toInt() ?? 10,
      calories: (map['calories'] as num?)?.toInt() ?? 100,
      completedAt: date,
    );
  }
}

class WorkoutService {
  WorkoutService._privateConstructor();
  static final WorkoutService instance = WorkoutService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves a completed workout session entry to Firestore
  Future<void> logCompletedWorkout({
    required String uid,
    required Workout workout,
    int? duration,
    int? calories,
  }) async {
    try {
      final now = DateTime.now();
      final recordDuration = duration ?? workout.duration;
      final recordCalories = calories ?? 140;

      await _db.collection('users').doc(uid).collection('workout_history').add({
        'workoutId': workout.id,
        'title': workout.title,
        'category': workout.category,
        'duration': recordDuration,
        'calories': recordCalories,
        'completedAt': FieldValue.serverTimestamp(),
        'dateKey':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });

      Helpers.log(
        'Logged completed workout "${workout.title}" ($recordDuration mins) for user: $uid',
      );
    } catch (e) {
      Helpers.log('Error logging completed workout: $e');
    }
  }

  /// Streams completed workouts for the active week (Monday 00:00 to Sunday 23:59)
  Stream<List<CompletedWorkoutRecord>> streamCurrentWeekWorkouts(String uid) {
    final now = DateTime.now();
    // Calculate Monday of current week
    final mondayDate = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final mondayStart = DateTime(
      mondayDate.year,
      mondayDate.month,
      mondayDate.day,
      0,
      0,
      0,
    );
    final sundayEnd = mondayStart.add(
      const Duration(days: 7, microseconds: -1),
    );

    return _db
        .collection('users')
        .doc(uid)
        .collection('workout_history')
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(mondayStart),
        )
        .where(
          'completedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(sundayEnd),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    CompletedWorkoutRecord.fromFirestore(doc.data(), doc.id),
              )
              .toList();
        })
        .handleError((e) {
          Helpers.log('Weekly completed workouts stream closed on auth change: $e');
          return <CompletedWorkoutRecord>[];
        });
  }

  /// Streams all historical completed workouts for a user
  Stream<List<CompletedWorkoutRecord>> streamAllCompletedWorkouts(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('workout_history')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    CompletedWorkoutRecord.fromFirestore(doc.data(), doc.id),
              )
              .toList();
        })
        .handleError((e) {
          Helpers.log('All completed workouts stream closed on auth change: $e');
          return <CompletedWorkoutRecord>[];
        });
  }

  /// Calculates consecutive active days up to today
  static int calculateStreakDays(Set<String> activeDateKeys) {
    if (activeDateKeys.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String formatDateKey(DateTime dt) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    final todayKey = formatDateKey(today);
    final yesterdayKey = formatDateKey(yesterday);

    if (!activeDateKeys.contains(todayKey) &&
        !activeDateKeys.contains(yesterdayKey)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = activeDateKeys.contains(todayKey) ? today : yesterday;

    while (activeDateKeys.contains(formatDateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Toggles favorite status for a workout in Firestore
  Future<bool> toggleFavorite({
    required String uid,
    required Workout workout,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(workout.id);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
        Helpers.log('Removed workout "${workout.title}" from favorites');
        return false;
      } else {
        await docRef.set({
          'id': workout.id,
          'title': workout.title,
          'category': workout.category,
          'duration': workout.duration,
          'difficulty': workout.difficulty,
          'type': workout.type,
          'equipment': workout.equipment,
          'imagePath': workout.imagePath,
          'videoUrl': workout.videoUrl,
          'videoId': workout.videoId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        Helpers.log('Added workout "${workout.title}" to favorites');
        return true;
      }
    } catch (e) {
      Helpers.log('Error toggling favorite workout: $e');
      rethrow;
    }
  }

  /// Streams user's favorite workouts
  Stream<List<Workout>> streamFavorites(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Workout.fromFirestore(doc.data(), doc.id))
              .toList();
        })
        .handleError((e) {
          Helpers.log('Favorites stream closed on auth change: $e');
          return <Workout>[];
        });
  }

  /// Streams boolean indicating if workout is favorited
  Stream<bool> streamIsFavorite(String uid, String workoutId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(workoutId)
        .snapshots()
        .map((snapshot) => snapshot.exists)
        .handleError((e) {
          Helpers.log('IsFavorite stream closed on auth change: $e');
          return false;
        });
  }
}
