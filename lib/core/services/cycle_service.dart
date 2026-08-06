import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';
import '../../features/cycle/presentation/screens/cycle_screen.dart';

class CycleService {
  CycleService._privateConstructor();
  static final CycleService instance = CycleService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate a date key in YYYY-MM-DD format for a given year, month, and day
  String formatDateKey(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  /// Save or update a daily cycle journal entry in Cloud Firestore
  Future<void> saveDailyLog({
    required String uid,
    required String dateKey,
    required DayJournal journal,
    int? dayNumber,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('cycle_logs')
          .doc(dateKey);

      final logData = <String, dynamic>{
        'dateKey': dateKey,
        'dayNumber': dayNumber,
        'moods': journal.moods,
        'symptoms': journal.symptoms,
        'energy': journal.energy,
        'notes': journal.notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(logData, SetOptions(merge: true));
      Helpers.log(
        'Saved cycle log to Firestore for dateKey: $dateKey (User: $uid)',
      );
    } catch (e) {
      Helpers.log('Error saving cycle log to Firestore: $e');
      rethrow;
    }
  }

  /// Stream daily cycle logs for a user from Cloud Firestore
  Stream<Map<String, DayJournal>> streamCycleLogs(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('cycle_logs')
        .snapshots()
        .map((snapshot) {
          final Map<String, DayJournal> result = {};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final moods = List<String>.from(data['moods'] ?? []);
            final symptoms = List<String>.from(data['symptoms'] ?? []);
            final energy = (data['energy'] as num?)?.toDouble() ?? 0.6;
            final notes = (data['notes'] as String?) ?? '';

            result[doc.id] = DayJournal(
              moods: moods,
              symptoms: symptoms,
              energy: energy,
              notes: notes,
            );
          }
          return result;
        });
  }

  /// Fetch user cycle logs for a specific month and year
  Future<Map<int, DayJournal>> getMonthLogs({
    required String uid,
    required int year,
    required int month,
  }) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('cycle_logs')
          .get();

      final Map<int, DayJournal> monthLogs = {};
      final monthPrefix = '$year-${month.toString().padLeft(2, '0')}';

      for (final doc in snapshot.docs) {
        if (doc.id.startsWith(monthPrefix)) {
          final data = doc.data();
          final parts = doc.id.split('-');
          if (parts.length == 3) {
            final day = int.tryParse(parts[2]);
            if (day != null) {
              monthLogs[day] = DayJournal(
                moods: List<String>.from(data['moods'] ?? []),
                symptoms: List<String>.from(data['symptoms'] ?? []),
                energy: (data['energy'] as num?)?.toDouble() ?? 0.6,
                notes: (data['notes'] as String?) ?? '',
              );
            }
          }
        }
      }
      return monthLogs;
    } catch (e) {
      Helpers.log('Error fetching month logs from Firestore: $e');
      return {};
    }
  }
}
