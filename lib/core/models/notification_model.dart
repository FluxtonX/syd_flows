import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String uid;
  final String title;
  final String message;
  final String category; // 'welcome', 'cycle', 'workout', 'insight'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.message,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'insight',
      isRead: data['isRead'] ?? false,
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'message': message,
      'category': category,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? message,
    String? category,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
