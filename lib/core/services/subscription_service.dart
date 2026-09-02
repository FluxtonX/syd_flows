import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage_service.dart';
import '../utils/helpers.dart';

class SubscriptionPlanModel {
  final String id;
  final String title;
  final String badge;
  final String subtitle;
  final String price;
  final String period;
  final String detail;
  final int trialDays;
  final bool enabled;

  const SubscriptionPlanModel({
    required this.id,
    required this.title,
    this.badge = '',
    required this.subtitle,
    required this.price,
    required this.period,
    required this.detail,
    this.trialDays = 0,
    this.enabled = true,
  });

  factory SubscriptionPlanModel.fromMap(
    Map<String, dynamic> map,
    String defaultId,
  ) {
    return SubscriptionPlanModel(
      id: (map['id'] as String?) ?? defaultId,
      title: (map['title'] as String?) ?? 'Subscription Plan',
      badge: (map['badge'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      price: (map['price'] as String?) ?? r'$4.99',
      period: (map['period'] as String?) ?? '/ month',
      detail: (map['detail'] as String?) ?? '',
      trialDays: (map['trialDays'] as num?)?.toInt() ?? 0,
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }
}

class SubscriptionPlansConfigModel {
  final String heroTagline;
  final String heroTitle;
  final String heroSubtitle;
  final List<SubscriptionPlanModel> plans;

  const SubscriptionPlansConfigModel({
    required this.heroTagline,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.plans,
  });

  static const SubscriptionPlansConfigModel defaults =
      SubscriptionPlansConfigModel(
        heroTagline: 'PERSONALISED WELLNESS',
        heroTitle: 'Feel supported\nin every phase.',
        heroSubtitle:
            'Unlock the complete workout library and deeper cycle guidance.',
        plans: [
          SubscriptionPlanModel(
            id: 'annual',
            title: 'Annual Plan',
            badge: 'BEST VALUE',
            subtitle: r'First 7 days free, then $59.99/yr',
            price: r'$4.99',
            period: '/ month (billed annually)',
            detail: r'$59.99 charged annually',
            trialDays: 7,
          ),
          SubscriptionPlanModel(
            id: 'monthly',
            title: 'Monthly Plan',
            subtitle: 'Flexible, cancel anytime',
            price: r'$9.99',
            period: '/ month',
            detail: 'Billed monthly',
            trialDays: 0,
          ),
        ],
      );

  factory SubscriptionPlansConfigModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;

    final plansList = map['plans'];
    List<SubscriptionPlanModel> parsedPlans = [];
    if (plansList is List) {
      for (var i = 0; i < plansList.length; i++) {
        if (plansList[i] is Map) {
          parsedPlans.add(
            SubscriptionPlanModel.fromMap(
              Map<String, dynamic>.from(plansList[i] as Map),
              i == 0 ? 'annual' : 'monthly',
            ),
          );
        }
      }
    }

    if (parsedPlans.isEmpty) {
      parsedPlans = defaults.plans;
    }

    return SubscriptionPlansConfigModel(
      heroTagline: (map['heroTagline'] as String?) ?? defaults.heroTagline,
      heroTitle: (map['heroTitle'] as String?) ?? defaults.heroTitle,
      heroSubtitle: (map['heroSubtitle'] as String?) ?? defaults.heroSubtitle,
      plans: parsedPlans,
    );
  }
}

/// Read-only live view of the subscription entitlement and dynamic plans from Firestore.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real-time stream of subscription plans & pricing configured from Web Admin
  Stream<SubscriptionPlansConfigModel> streamSubscriptionPlans() {
    return _db
        .collection('videos')
        .doc('_settings_plans')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return SubscriptionPlansConfigModel.fromMap(doc.data());
          }
          return SubscriptionPlansConfigModel.defaults;
        })
        .handleError((e) {
          Helpers.log('Error streaming subscription plans: $e');
          return SubscriptionPlansConfigModel.defaults;
        });
  }

  /// Real-time stream indicating whether the active signed-in user has premium entitlement
  Stream<bool> streamHasPremiumAccess() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<bool>.value(false);

      // Clean up any stale local mock keys from previous runs
      LocalStorageService.instance.remove('static_premium_access_${user.uid}');

      return Stream<bool>.multi((controller) {
        var hasUserDocSubscription = false;
        var hasActiveRequest = false;

        void emitAccess() {
          if (!controller.isClosed) {
            controller.add(hasUserDocSubscription || hasActiveRequest);
          }
        }

        // 1. Listen to users/{uid} document for live subscription state
        final userDocSubscription = _db
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen(
              (snapshot) {
                final data = snapshot.data();
                hasUserDocSubscription = _hasActiveFirebaseSubscription(data);
                emitAccess();
              },
              onError: (e) {
                Helpers.log('Subscription user stream error: $e');
                hasUserDocSubscription = false;
                emitAccess();
              },
            );

        // 2. Listen to users/{uid}/subscription_requests subcollection for approved/active requests
        final requestsSubscription = _db
            .collection('users')
            .doc(user.uid)
            .collection('subscription_requests')
            .snapshots()
            .listen(
              (snapshot) {
                hasActiveRequest = snapshot.docs.any((doc) {
                  final status = doc.data()['status']?.toString().toLowerCase();
                  return status == 'active' || status == 'approved';
                });
                emitAccess();
              },
              onError: (e) {
                Helpers.log('Subscription requests stream error: $e');
                hasActiveRequest = false;
                emitAccess();
              },
            );

        controller.onCancel = () {
          userDocSubscription.cancel();
          requestsSubscription.cancel();
        };
      });
    });
  }

  /// Real-time stream of detailed subscription metadata and approval status
  Stream<UserSubscriptionStatus> streamUserSubscriptionStatus() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(UserSubscriptionStatus.inactive);
      }

      return Stream<UserSubscriptionStatus>.multi((controller) {
        var isPrem = false;
        var reqStatus = 'none';
        var planName = 'Annual Plan';

        void emitStatus() {
          if (!controller.isClosed) {
            final active = isPrem || reqStatus == 'approved' || reqStatus == 'active';
            controller.add(
              UserSubscriptionStatus(
                isPremium: active,
                status: active ? 'active' : (reqStatus == 'pending' ? 'pending' : 'inactive'),
                planTitle: planName,
              ),
            );
          }
        }

        final userSub = _db.collection('users').doc(user.uid).snapshots().listen((snap) {
          final data = snap.data();
          isPrem = _hasActiveFirebaseSubscription(data);
          final pId = data?['subscription']?['planId']?.toString();
          if (pId != null) {
            planName = pId.toLowerCase() == 'monthly' ? 'Monthly Plan' : 'Annual Plan';
          }
          emitStatus();
        });

        final reqSub = _db
            .collection('users')
            .doc(user.uid)
            .collection('subscription_requests')
            .snapshots()
            .listen((snap) {
              if (snap.docs.isNotEmpty) {
                final d = snap.docs.first.data();
                reqStatus = d['status']?.toString().toLowerCase() ?? 'none';
                final pId = d['planId']?.toString();
                if (pId != null) {
                  planName = pId.toLowerCase() == 'monthly' ? 'Monthly Plan' : 'Annual Plan';
                }
              } else {
                reqStatus = 'none';
              }
              emitStatus();
            });

        controller.onCancel = () {
          userSub.cancel();
          reqSub.cancel();
        };
      });
    });
  }

  bool _hasActiveFirebaseSubscription(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    if (userData['isPremium'] == true) return true;

    final subscription = userData['subscription'];
    if (subscription is! Map) return false;

    final status = subscription['status']?.toString().toLowerCase();
    if (status != 'active' && status != 'trialing') return false;

    final expiry = subscription['expiresAt'];
    if (expiry is Timestamp) {
      return expiry.toDate().isAfter(DateTime.now());
    }
    return true;
  }

  /// Records the user's selected plan in Firestore with full user metadata.
  Future<void> requestSubscription({required String planId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before subscribing.');
    }

    String email = user.email ?? '';
    String name = user.displayName ?? '';

    if (name.isEmpty || email.isEmpty) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (name.isEmpty) {
            name = (data['displayName'] as String?) ?? '';
          }
          if (email.isEmpty) {
            email = (data['email'] as String?) ?? '';
          }
        }
      } catch (_) {}
    }

    // Clean up any old duplicate request documents for this user
    try {
      final oldDocs = await _db
          .collection('users')
          .doc(user.uid)
          .collection('subscription_requests')
          .get();
      for (var d in oldDocs.docs) {
        if (d.id != 'current') {
          await d.reference.delete();
        }
      }
    } catch (_) {}

    // Save as single authoritative 'current' request document
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('subscription_requests')
        .doc('current')
        .set({
          'userId': user.uid,
          'userEmail': email,
          'displayName': name.isNotEmpty
              ? name
              : (email.isNotEmpty ? email.split('@')[0] : 'App User'),
          'planId': planId,
          'status': 'pending',
          'source': 'mobile_app',
          'requestedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}

class UserSubscriptionStatus {
  final bool isPremium;
  final String status; // 'active', 'pending', 'inactive'
  final String planTitle;

  const UserSubscriptionStatus({
    required this.isPremium,
    required this.status,
    required this.planTitle,
  });

  static const UserSubscriptionStatus inactive = UserSubscriptionStatus(
    isPremium: false,
    status: 'inactive',
    planTitle: 'Annual Plan',
  );
}
