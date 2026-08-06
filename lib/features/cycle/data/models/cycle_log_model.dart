import 'package:cloud_firestore/cloud_firestore.dart';
import '../../presentation/screens/cycle_screen.dart';

class CycleLogModel {
  final String dateKey;
  final int? dayNumber;
  final List<String> moods;
  final List<String> symptoms;
  final double energy;
  final String notes;
  final DateTime? updatedAt;

  CycleLogModel({
    required this.dateKey,
    this.dayNumber,
    required this.moods,
    required this.symptoms,
    required this.energy,
    required this.notes,
    this.updatedAt,
  });

  factory CycleLogModel.fromDayJournal(String dateKey, DayJournal journal, {int? dayNumber}) {
    return CycleLogModel(
      dateKey: dateKey,
      dayNumber: dayNumber,
      moods: journal.moods,
      symptoms: journal.symptoms,
      energy: journal.energy,
      notes: journal.notes,
    );
  }

  DayJournal toDayJournal() {
    return DayJournal(
      moods: moods,
      symptoms: symptoms,
      energy: energy,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'dayNumber': dayNumber,
      'moods': moods,
      'symptoms': symptoms,
      'energy': energy,
      'notes': notes,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory CycleLogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CycleLogModel(
      dateKey: doc.id,
      dayNumber: data['dayNumber'] as int?,
      moods: List<String>.from(data['moods'] ?? []),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      energy: (data['energy'] as num?)?.toDouble() ?? 0.6,
      notes: (data['notes'] as String?) ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
