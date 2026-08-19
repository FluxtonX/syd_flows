import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage_service.dart';

/// Read-only view of the entitlement written by the verified payment backend.
///
/// Expected Firestore shape:
/// users/{uid}/subscription: { status: 'active', planId: 'monthly',
/// expiresAt: Timestamp, source: 'app_store' }
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamController<void> _staticAccessChanged =
      StreamController<void>.broadcast();

  String _staticAccessKey(String uid) => 'static_premium_access_$uid';

  Stream<bool> streamHasPremiumAccess() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<bool>.value(false);

      return Stream<bool>.multi((controller) {
        var hasStaticAccess = false;
        var hasFirebaseAccess = false;

        void emitAccess() => controller.add(hasStaticAccess || hasFirebaseAccess);

        final firebaseSubscription = _db
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
              hasFirebaseAccess = _hasActiveFirebaseSubscription(snapshot.data());
              emitAccess();
            }, onError: (_, __) => emitAccess());

        final staticSubscription = _staticAccessChanged.stream.listen((_) async {
          hasStaticAccess =
              await LocalStorageService.instance.getBool(_staticAccessKey(user.uid)) ??
              false;
          emitAccess();
        });

        LocalStorageService.instance.getBool(_staticAccessKey(user.uid)).then((value) {
          hasStaticAccess = value ?? false;
          emitAccess();
        });

        controller.onCancel = () {
          firebaseSubscription.cancel();
          staticSubscription.cancel();
        };
      });
    });
  }

  bool _hasActiveFirebaseSubscription(Map<String, dynamic>? userData) {
    final subscription = userData?['subscription'];
    if (subscription is! Map) return false;

    final status = subscription['status']?.toString().toLowerCase();
    if (status != 'active' && status != 'trialing') return false;

    final expiry = subscription['expiresAt'];
    return expiry is! Timestamp || expiry.toDate().isAfter(DateTime.now());
  }

  /// Records the user's selected plan and enables the temporary local test
  /// entitlement. Production access must come from the verified backend.
  Future<void> requestSubscription({required String planId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before subscribing.');
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('subscription_requests')
        .add({
          'planId': planId,
          'status': 'pending',
          'source': 'mobile_app',
          'requestedAt': FieldValue.serverTimestamp(),
        });

    // Temporary test entitlement: remember the chosen subscription locally.
    // Replace this with verified store/webhook activation before production.
    await LocalStorageService.instance.saveBool(_staticAccessKey(user.uid), true);
    _staticAccessChanged.add(null);
  }
}
