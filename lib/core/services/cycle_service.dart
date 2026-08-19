import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';
import '../../features/cycle/data/models/cycle_types.dart';
import '../../features/cycle/data/models/period_record.dart';

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

  /// Save or update a daily cycle journal entry in Cloud Firestore.
  ///
  /// [isPeriodStart] marks this day as the confirmed start of a new period.
  /// When true, a separate PeriodRecord is ALSO written to the periods subcollection.
  Future<void> saveDailyLog({
    required String uid,
    required String dateKey,
    required DayJournal journal,
    int? dayNumber,
    bool isPeriodStart = false,
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
        'flow': journal.flow,
        'moods': journal.moods,
        'symptoms': journal.symptoms,
        'energy': journal.energy,
        'notes': journal.notes,
        'isPeriodStart': isPeriodStart,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(logData, SetOptions(merge: true));
      Helpers.log(
        'Saved cycle log to Firestore for dateKey: $dateKey (User: $uid)',
      );

      // When a period start is confirmed, also write to the periods subcollection
      if (isPeriodStart) {
        final periodDate = DateTime.tryParse(dateKey) ?? DateTime.now();
        await savePeriodRecord(uid: uid, startDate: periodDate);
      }
    } catch (e) {
      Helpers.log('Error saving cycle log to Firestore: $e');
      rethrow;
    }
  }

  /// Write a confirmed period start to the periods subcollection.
  ///
  /// Firestore path: users/{uid}/periods/{dateKey}
  Future<void> savePeriodRecord({
    required String uid,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final y = startDate.year.toString();
      final m = startDate.month.toString().padLeft(2, '0');
      final d = startDate.day.toString().padLeft(2, '0');
      final periodId = '$y-$m-$d';

      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('periods')
          .doc(periodId);

      final data = <String, dynamic>{
        'startDate': periodId,
        if (endDate != null)
          'endDate':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
      Helpers.log('Saved period record: $periodId (User: $uid)');
    } catch (e) {
      Helpers.log('Error saving period record: $e');
      // Non-fatal
    }
  }

  /// Streams the user's confirmed period records in descending chronological order.
  Stream<List<PeriodRecord>> streamPeriodRecords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('periods')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PeriodRecord.fromFirestore(doc))
              .toList();
        })
        .handleError((e) {
          Helpers.log('Period records stream closed on auth change: $e');
          return <PeriodRecord>[];
        });
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
            final flow = data['flow'] as String?;
            final moods = List<String>.from(data['moods'] ?? []);
            final symptoms = List<String>.from(data['symptoms'] ?? []);
            final energy = (data['energy'] as num?)?.toDouble() ?? 0.6;
            final notes = (data['notes'] as String?) ?? '';
            final isPeriodStart = (data['isPeriodStart'] as bool?) ?? false;

            result[doc.id] = DayJournal(
              flow: flow,
              moods: moods,
              symptoms: symptoms,
              energy: energy,
              notes: notes,
              isPeriodStart: isPeriodStart,
            );
          }
          return result;
        })
        .handleError((e) {
          Helpers.log('Cycle logs stream closed on auth change: $e');
          return <String, DayJournal>{};
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

  /// Fetch all historical user cycle logs for data export (CSV)
  Future<Map<String, DayJournal>> fetchAllCycleLogs(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('cycle_logs')
          .get();

      final Map<String, DayJournal> logsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        logsMap[doc.id] = DayJournal(
          flow: data['flow'] as String?,
          moods: List<String>.from(data['moods'] ?? []),
          symptoms: List<String>.from(data['symptoms'] ?? []),
          energy: (data['energy'] as num?)?.toDouble() ?? 0.6,
          notes: (data['notes'] as String?) ?? '',
          isPeriodStart: (data['isPeriodStart'] as bool?) ?? false,
        );
      }
      return logsMap;
    } catch (e) {
      Helpers.log('Error fetching all cycle logs for export: $e');
      return {};
    }
  }
}
