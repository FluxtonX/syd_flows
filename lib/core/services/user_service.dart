import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../utils/helpers.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class UserService {
  UserService._privateConstructor();
  static final UserService instance = UserService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update base user profile in Firestore
  Future<void> saveUserProfile(User user, {String? displayName}) async {
    try {
      final userDocRef = _db.collection('users').doc(user.uid);
      final docSnap = await userDocRef.get();

      final dataToSave = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (!docSnap.exists) {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        await userDocRef.set(dataToSave, SetOptions(merge: true));
        Helpers.log('Created new user profile in Firestore: ${user.uid}');
      } else {
        await userDocRef.update(dataToSave);
        Helpers.log('Updated user profile in Firestore: ${user.uid}');
      }
    } catch (e) {
      Helpers.log('Error saving user profile to Firestore: $e');
      // Non-fatal if offline/unreachable, but log error
    }
  }

  // Save Setup Flow responses to Firestore
  Future<void> saveSetupFlowData({
    required String uid,
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
    required String fitnessLevel,
    required List<String> selectedGoals,
    required List<String> selectedEquipment,
  }) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      await userDocRef.set({
        'setupFlow': {
          'lastPeriodStart': lastPeriodStart.toIso8601String(),
          'cycleLength': cycleLength,
          'periodLength': periodLength,
          'fitnessLevel': fitnessLevel,
          'selectedGoals': selectedGoals,
          'selectedEquipment': selectedEquipment,
          'updatedAt': FieldValue.serverTimestamp(),
          'isCompleted': true,
        },
        'hasCompletedSetup': true,
      }, SetOptions(merge: true));
      Helpers.log('Saved setup flow data for user: $uid');
    } catch (e) {
      Helpers.log('Error saving setup flow data to Firestore: $e');
      rethrow;
    }
  }

  // Check if user has completed Onboarding & User Setup Flow
  Future<bool> hasUserCompletedSetup(String uid) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      final docSnap = await userDocRef.get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null) {
          final hasCompleted = data['hasCompletedSetup'] == true ||
              (data['setupFlow'] is Map && (data['setupFlow']['isCompleted'] == true));
          return hasCompleted;
        }
      }
    } catch (e) {
      Helpers.log('Error checking if user completed setup: $e');
    }
    return false;
  }

  // Update User Profile and Cycle Preferences
  Future<void> updateUserProfileAndPreferences({
    required String uid,
    required String displayName,
    required int cycleLength,
    required int periodLength,
    required String fitnessLevel,
    required List<String> selectedGoals,
  }) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      await userDocRef.set({
        'displayName': displayName.trim(),
        'setupFlow': {
          'cycleLength': cycleLength,
          'periodLength': periodLength,
          'fitnessLevel': fitnessLevel,
          'selectedGoals': selectedGoals,
          'updatedAt': FieldValue.serverTimestamp(),
          'isCompleted': true,
        },
        'hasCompletedSetup': true,
      }, SetOptions(merge: true));

      final user = AuthService.instance.currentUser;
      if (user != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      Helpers.log('Updated user profile and preferences for: $uid');
    } catch (e) {
      Helpers.log('Error updating user profile in Firestore: $e');
      rethrow;
    }
  }

  // Get user profile data stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- Notifications Firestore Integration ---

  // Send notification to Firestore and trigger local notification
  Future<void> sendNotification({
    required String uid,
    required String title,
    required String message,
    String category = 'insight',
    String? customId,
  }) async {
    try {
      final docRef = customId != null
          ? _db.collection('users').doc(uid).collection('notifications').doc(customId)
          : _db.collection('users').doc(uid).collection('notifications').doc();

      await docRef.set({
        'uid': uid,
        'title': title,
        'message': message,
        'category': category,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Fire local device push notification
      await NotificationService.instance.showNotification(
        id: docRef.id.hashCode,
        title: title,
        body: message,
      );

      Helpers.log('Notification sent successfully to user $uid: $title');
    } catch (e) {
      Helpers.log('Error sending notification: $e');
    }
  }

  // Send Welcome Notification if not already sent for this user
  Future<void> sendWelcomeNotificationIfNeeded(String uid, {String? name}) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('welcome_notification');

      final snap = await docRef.get();
      if (!snap.exists) {
        final userName = name?.isNotEmpty == true
            ? name!
            : (AuthService.instance.currentUser?.displayName ?? 'there');

        await sendNotification(
          uid: uid,
          title: 'Welcome to SYD FLOW! 🌸',
          message:
              'Welcome $userName! Your personal wellness & cycle tracking journey starts now. Explore your daily flow insights!',
          category: 'welcome',
          customId: 'welcome_notification',
        );
      }
    } catch (e) {
      Helpers.log('Error checking/sending welcome notification: $e');
    }
  }

  // Realtime stream of user notifications
  Stream<List<NotificationModel>> getNotificationsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // Realtime stream of unread notification count
  Stream<int> getUnreadNotificationsCountStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark single notification as read
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      Helpers.log('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String uid) async {
    try {
      final unreadDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      Helpers.log('Marked all notifications as read for user: $uid');
    } catch (e) {
      Helpers.log('Error marking all notifications as read: $e');
    }
  }
}
