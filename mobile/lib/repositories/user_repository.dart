import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/user_roles.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/auth_debug.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static final Map<String, Future<AppUser>> _ensureInFlight = {};

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) {
        AuthDebug.profile('getUser: no doc uid=$userId');
        return null;
      }
      return AppUser.fromFirestore(doc);
    } catch (e, st) {
      AuthDebug.firestore('getUser error: $e\n$st');
      rethrow;
    }
  }

  Stream<AppUser?> watchUser(String userId) {
    AppUser? _last;
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        AuthDebug.profile('watchUser: snapshot missing uid=$userId');
        return null;
      }
      final user = AppUser.fromFirestore(doc);
      AuthDebug.profile('watchUser: loaded uid=$userId role=${user.role.value}');
      return user;
    }).where((user) {
      // Drop duplicate emissions (cache hit followed by server confirm)
      if (user?.id == _last?.id &&
          user?.role == _last?.role &&
          user?.displayName == _last?.displayName) {
        return false;
      }
      _last = user;
      return true;
    });
  }

  /// Creates or updates `users/{uid}` once per in-flight call (merge write).
  Future<AppUser> ensureUserProfile({
    required String userId,
    required String email,
    String displayName = 'User',
    UserRole role = UserRole.customer,
    String? photoUrl,
  }) {
    final existing = _ensureInFlight[userId];
    if (existing != null) {
      AuthDebug.firestore('ensureUserProfile: reusing in-flight uid=$userId');
      return existing;
    }

    final future = _ensureUserProfileOnce(
      userId: userId,
      email: email,
      displayName: displayName,
      role: role,
      photoUrl: photoUrl,
    );
    _ensureInFlight[userId] = future;
    return future.whenComplete(() => _ensureInFlight.remove(userId));
  }

  Future<AppUser> _ensureUserProfileOnce({
    required String userId,
    required String email,
    String displayName = 'User',
    UserRole role = UserRole.customer,
    String? photoUrl,
  }) async {
    AuthDebug.firestore(
      'ensureUserProfile start uid=$userId role=${role.value}',
    );

    final currentAuth = FirebaseAuth.instance.currentUser;
    if (currentAuth == null) {
      throw const AppException('Not signed in — cannot create profile.');
    }
    if (currentAuth.uid != userId) {
      throw const AppException('Auth user mismatch — cannot create profile.');
    }

    final docRef = _users.doc(userId);
    final now = DateTime.now();
    final trimmedName =
        displayName.trim().isEmpty ? 'User' : displayName.trim();

    try {
      final existing = await docRef.get();
      // If caller explicitly passes a non-default role, honour it.
      // Only fall back to existing role when caller passes the default (customer).
      final resolvedRole = (role != UserRole.customer || !existing.exists)
          ? role
          : UserRole.fromString(existing.data()?['role'] as String?);

      final payload = <String, dynamic>{
        'uid': userId,
        'id': userId,
        'email': email.trim(),
        'displayName': existing.exists
            ? (trimmedName != 'User'
                ? trimmedName
                : (existing.data()?['displayName'] as String? ?? trimmedName))
            : trimmedName,
        'role': resolvedRole.value,
        'updatedAt': Timestamp.fromDate(now),
        'isActive': true,
      };

      if (!existing.exists) {
        payload['createdAt'] = Timestamp.fromDate(now);
        payload['savedShopIds'] = <String>[];
      }

      if (photoUrl != null) {
        payload['photoUrl'] = photoUrl;
      }

      await docRef.set(payload, SetOptions(merge: true));
      AuthDebug.firestore(
        existing.exists
            ? 'ensureUserProfile: merged users/$userId'
            : 'ensureUserProfile: created users/$userId',
      );

      // Build AppUser directly from the payload we just wrote —
      // avoids a redundant round-trip that triggers a duplicate watchUser snapshot.
      final resolvedCreatedAt = existing.exists
          ? (existing.data()?['createdAt'] as Timestamp?)?.toDate() ?? now
          : now;
      final profile = AppUser(
        id: userId,
        email: (payload['email'] as String),
        displayName: (payload['displayName'] as String),
        role: resolvedRole,
        photoUrl: photoUrl,
        createdAt: resolvedCreatedAt,
        updatedAt: now,
        savedShopIds: existing.exists
            ? List<String>.from(existing.data()?['savedShopIds'] ?? [])
            : [],
        isActive: true,
      );
      AuthDebug.firestore(
        'ensureUserProfile: success uid=${profile.uid} role=${profile.role.value}',
      );
      return profile;
    } on FirebaseException catch (e) {
      AuthDebug.firestore(
        'ensureUserProfile FirebaseException: ${e.code} ${e.message}',
      );
      throw AppException(
        'Could not save profile: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e, st) {
      AuthDebug.firestore('ensureUserProfile error: $e\n$st');
      if (e is AppException) rethrow;
      throw AppException('Could not save profile: $e');
    }
  }

  Future<AppUser> createOrUpdateUser({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
    UserRole role = UserRole.customer,
  }) {
    return ensureUserProfile(
      userId: userId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
    );
  }

  Future<void> updateUser(AppUser user) async {
    await _users.doc(user.id).set(
          user.copyWith(updatedAt: DateTime.now()).toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateFcmToken(String userId, String? token) async {
    await _users.doc(userId).set(
      {
        'uid': userId,
        'fcmToken': token,
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> toggleSavedShop(String userId, String shopId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) {
      throw const AppException('User not found');
    }
    final user = AppUser.fromFirestore(doc);
    final saved = List<String>.from(user.savedShopIds);
    if (saved.contains(shopId)) {
      saved.remove(shopId);
    } else {
      saved.add(shopId);
    }
    await _users.doc(userId).update({
      'savedShopIds': saved,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<AppUser>> getUsersByRole(UserRole role, {int limit = 50}) async {
    final snapshot = await _users
        .where('role', isEqualTo: role.value)
        .limit(limit)
        .get();
    return snapshot.docs.map(AppUser.fromFirestore).toList();
  }
}
