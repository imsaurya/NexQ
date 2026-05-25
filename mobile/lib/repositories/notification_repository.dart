import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_collections.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.notificationsPageSize)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? shopId,
    String? requestId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final notification = AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      shopId: shopId,
      requestId: requestId,
      createdAt: now,
      updatedAt: now,
    );
    await _notifications.doc(id).set(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'isRead': true,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}
