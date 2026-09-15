import 'package:cloud_firestore/cloud_firestore.dart';
import 'cycle_types.dart';

/// PeriodRecord represents a CONFIRMED period start event.
///
/// This is the authoritative source for new cycle anchors.
/// A daily log with flow != null is NOT sufficient — only an explicit
/// PeriodRecord (or a daily log with isPeriodStart == true) creates a new cycle.
///
/// Firestore path: users/{uid}/periods/{id}
class PeriodRecord {
  final String id;

  /// Calendar date the period started. Stored as YYYY-MM-DD string in Firestore.
  final DateTime startDate;

  /// Calendar date the period ended (null if still ongoing).
  final DateTime? endDate;

  /// Duration in days (calculated or user-provided).
  final int? duration;

  /// Source authority of this period record (user_confirmed, user_corrected, etc.)
  final PeriodSource source;

  /// Confidence rating (0.0 to 1.0, defaults to 1.0 for user observations)
  final double confidence;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const PeriodRecord({
    required this.id,
    required this.startDate,
    this.endDate,
    this.duration,
    this.source = PeriodSource.userConfirmed,
    this.confidence = 1.0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Parses a PeriodRecord from a Firestore DocumentSnapshot.
  factory PeriodRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final startDateStr = data['startDate'] as String?;
    final DateTime startDate = startDateStr != null
        ? (DateTime.tryParse(startDateStr) ?? DateTime.now())
        : DateTime.now();

    final endDateStr = data['endDate'] as String?;
    final DateTime? endDate = endDateStr != null
        ? DateTime.tryParse(endDateStr)
        : null;

    final createdAtTs = data['createdAt'];
    final DateTime createdAt = createdAtTs is Timestamp
        ? createdAtTs.toDate()
        : DateTime.now();

    final updatedAtTs = data['updatedAt'];
    final DateTime? updatedAt = updatedAtTs is Timestamp
        ? updatedAtTs.toDate()
        : null;

    final sourceStr = data['source'] as String?;
    final source = PeriodSource.parse(sourceStr);
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 1.0;

    return PeriodRecord(
      id: doc.id,
      startDate: startDate,
      endDate: endDate,
      duration: (data['duration'] as num?)?.toInt(),
      source: source,
      confidence: confidence,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts this record to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'startDate': _toDateKey(startDate),
      if (endDate != null) 'endDate': _toDateKey(endDate!),
      if (duration != null) 'duration': duration,
      'source': source.label,
      'confidence': confidence,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String _toDateKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  String toString() =>
      'PeriodRecord(id: $id, startDate: ${_toDateKey(startDate)})';
}
