import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/firestore_collections.dart';
import '../core/errors/app_exception.dart';
import '../models/active_token.dart';
import '../models/app_notification.dart';
import '../models/queue_request.dart';
import '../repositories/notification_repository.dart';

/// Core realtime queue engine — handles token assignment, movement, and lifecycle.
class QueueEngineService {
  QueueEngineService({
    required FirebaseFirestore firestore,
    required NotificationRepository notificationRepository,
  })  : _firestore = firestore,
        _notifications = notificationRepository;

  final FirebaseFirestore _firestore;
  final NotificationRepository _notifications;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(FirestoreCollections.queueRequests);

  CollectionReference<Map<String, dynamic>> get _tokens =>
      _firestore.collection(FirestoreCollections.activeTokens);

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestoreCollections.shops);

  /// Customer submits a queue request (no duplicate active requests per shop).
  Future<QueueRequest> submitRequest({
    required String shopId,
    required String customerId,
    required String customerName,
    required String serviceId,
    required String serviceName,
    String? preferredTime,
    String? note,
  }) async {
    final existing = await _requests
        .where('shopId', isEqualTo: shopId)
        .where('customerId', isEqualTo: customerId)
        .where('status', whereIn: [
          QueueRequestStatus.pending.name,
          QueueRequestStatus.approved.name,
          QueueRequestStatus.delayed.name,
        ])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const AppException('You already have an active queue request for this shop.');
    }

    final now = DateTime.now();
    final id = _uuid.v4();
    final request = QueueRequest(
      id: id,
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      serviceId: serviceId,
      serviceName: serviceName,
      status: QueueRequestStatus.pending,
      preferredTime: preferredTime,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    await _requests.doc(id).set(request.toMap());
    return request;
  }

  /// Owner approves request and assigns next token atomically.
  Future<void> approveRequest(String requestId) async {
    await _firestore.runTransaction((txn) async {
      final requestRef = _requests.doc(requestId);
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) {
        throw const AppException('Request not found');
      }

      final request = QueueRequest.fromFirestore(requestSnap);
      if (request.status != QueueRequestStatus.pending) {
        throw const AppException('Request is not pending');
      }

      final shopRef = _shops.doc(request.shopId);
      final shopSnap = await txn.get(shopRef);
      if (!shopSnap.exists) {
        throw const AppException('Shop not found');
      }

      final shopData = shopSnap.data()!;
      final nextToken = (shopData['currentToken'] as int? ?? 0) + 1;
      final waitingCount = (shopData['waitingCount'] as int? ?? 0) + 1;

      txn.update(shopRef, {
        'currentToken': nextToken,
        'waitingCount': waitingCount,
        'updatedAt': Timestamp.now(),
      });

      txn.update(requestRef, {
        'status': QueueRequestStatus.approved.name,
        'tokenNumber': nextToken,
        'peopleAhead': waitingCount - 1,
        'updatedAt': Timestamp.now(),
      });

      final tokenId = _uuid.v4();
      txn.set(_tokens.doc(tokenId), ActiveToken(
        id: tokenId,
        shopId: request.shopId,
        requestId: requestId,
        customerId: request.customerId,
        customerName: request.customerName,
        tokenNumber: nextToken,
        serviceName: request.serviceName,
        position: waitingCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());
    });

    final request = await _getRequest(requestId);
    if (request != null) {
      await _notifications.createNotification(
        userId: request.customerId,
        title: 'Queue Approved',
        body: 'Your token #${request.tokenNumber} is confirmed.',
        type: NotificationType.requestApproved,
        shopId: request.shopId,
        requestId: requestId,
      );
    }
  }

  Future<void> rejectRequest(String requestId, {String? reason}) async {
    final request = await _getRequest(requestId);
    if (request == null) throw const AppException('Request not found');

    await _requests.doc(requestId).update({
      'status': QueueRequestStatus.rejected.name,
      'note': reason ?? request.note,
      'updatedAt': Timestamp.now(),
    });

    await _notifications.createNotification(
      userId: request.customerId,
      title: 'Request Rejected',
      body: reason ?? 'Your queue request was rejected.',
      type: NotificationType.requestRejected,
      shopId: request.shopId,
      requestId: requestId,
    );
  }

  Future<void> delayRequest(String requestId, {int delayMinutes = 15}) async {
    await _firestore.runTransaction((txn) async {
      final requestRef = _requests.doc(requestId);
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) throw const AppException('Request not found');

      final request = QueueRequest.fromFirestore(requestSnap);
      if (request.tokenNumber == null) {
        throw const AppException('Token not assigned yet');
      }

      txn.update(requestRef, {
        'status': QueueRequestStatus.delayed.name,
        'delayMinutes': delayMinutes,
        'updatedAt': Timestamp.now(),
      });

      final tokenQuery = await _tokens
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (tokenQuery.docs.isNotEmpty) {
        txn.update(tokenQuery.docs.first.reference, {
          'isDelayed': true,
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }

  Future<void> cancelRequest(String requestId) async {
    await _firestore.runTransaction((txn) async {
      final requestRef = _requests.doc(requestId);
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) return;

      final request = QueueRequest.fromFirestore(requestSnap);
      txn.update(requestRef, {
        'status': QueueRequestStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });

      if (request.tokenNumber != null) {
        final shopRef = _shops.doc(request.shopId);
        final shopSnap = await txn.get(shopRef);
        if (shopSnap.exists) {
          final waiting = (shopSnap.data()!['waitingCount'] as int? ?? 1) - 1;
          txn.update(shopRef, {
            'waitingCount': waiting < 0 ? 0 : waiting,
            'updatedAt': Timestamp.now(),
          });
        }

        final tokenSnap = await _tokens
            .where('requestId', isEqualTo: requestId)
            .limit(1)
            .get();
        for (final doc in tokenSnap.docs) {
          txn.delete(doc.reference);
        }
      }
    });
  }

  Future<void> nextToken(String shopId) async {
    await _firestore.runTransaction((txn) async {
      final shopRef = _shops.doc(shopId);
      final shopSnap = await txn.get(shopRef);
      if (!shopSnap.exists) throw const AppException('Shop not found');

      final shopData = shopSnap.data()!;
      if (shopData['queuePaused'] == true) {
        throw const AppException('Queue is paused');
      }

      final currentServing = shopData['servingToken'] as int? ?? 0;
      final nextServing = currentServing + 1;

      txn.update(shopRef, {
        'servingToken': nextServing,
        'waitingCount': ((shopData['waitingCount'] as int? ?? 1) - 1).clamp(0, 999),
        'updatedAt': Timestamp.now(),
      });

      // Complete previous serving token
      final prevTokens = await _tokens
          .where('shopId', isEqualTo: shopId)
          .where('isServing', isEqualTo: true)
          .get();

      for (final doc in prevTokens.docs) {
        txn.update(doc.reference, {
          'isServing': false,
          'updatedAt': Timestamp.now(),
        });
        txn.update(_requests.doc(doc.data()['requestId'] as String), {
          'status': QueueRequestStatus.completed.name,
          'updatedAt': Timestamp.now(),
        });
      }

      // Mark next token as serving
      final nextTokenQuery = await _tokens
          .where('shopId', isEqualTo: shopId)
          .where('tokenNumber', isEqualTo: nextServing)
          .limit(1)
          .get();

      if (nextTokenQuery.docs.isNotEmpty) {
        final tokenDoc = nextTokenQuery.docs.first;
        txn.update(tokenDoc.reference, {
          'isServing': true,
          'updatedAt': Timestamp.now(),
        });
      }
    });

    await _notifyTurnSoon(shopId);
  }

  Future<void> skipToken(String shopId) async {
    final shopSnap = await _shops.doc(shopId).get();
    if (!shopSnap.exists) return;

    final servingToken = shopSnap.data()!['servingToken'] as int? ?? 0;
    final tokenQuery = await _tokens
        .where('shopId', isEqualTo: shopId)
        .where('tokenNumber', isEqualTo: servingToken)
        .limit(1)
        .get();

    if (tokenQuery.docs.isEmpty) return;

    final token = ActiveToken.fromFirestore(tokenQuery.docs.first);
    await _tokens.doc(token.id).delete();
    await _requests.doc(token.requestId).update({
      'status': QueueRequestStatus.cancelled.name,
      'updatedAt': Timestamp.now(),
    });

    await _notifications.createNotification(
      userId: token.customerId,
      title: 'Token Skipped',
      body: 'Your token #${token.tokenNumber} was skipped.',
      type: NotificationType.tokenSkipped,
      shopId: shopId,
      requestId: token.requestId,
    );

    await nextToken(shopId);
  }

  Stream<List<QueueRequest>> watchShopRequests(String shopId) {
    return _requests
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(QueueRequest.fromFirestore).toList());
  }

  Stream<List<QueueRequest>> watchCustomerRequests(String customerId) {
    return _requests
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(QueueRequest.fromFirestore).toList());
  }

  Stream<List<ActiveToken>> watchActiveTokens(String shopId) {
    return _tokens
        .where('shopId', isEqualTo: shopId)
        .orderBy('tokenNumber')
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(ActiveToken.fromFirestore).toList());
  }

  Stream<QueueRequest?> watchCustomerActiveRequest(String shopId, String customerId) {
    return _requests
        .where('shopId', isEqualTo: shopId)
        .where('customerId', isEqualTo: customerId)
        .where('status', whereIn: [
          QueueRequestStatus.approved.name,
          QueueRequestStatus.delayed.name,
        ])
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : QueueRequest.fromFirestore(s.docs.first));
  }

  Future<QueueRequest?> _getRequest(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    if (!doc.exists) return null;
    return QueueRequest.fromFirestore(doc);
  }

  Future<void> _notifyTurnSoon(String shopId) async {
    final shopSnap = await _shops.doc(shopId).get();
    if (!shopSnap.exists) return;

    final serving = shopSnap.data()!['servingToken'] as int? ?? 0;
    final upcoming = await _tokens
        .where('shopId', isEqualTo: shopId)
        .where('tokenNumber', isEqualTo: serving + 2)
        .limit(1)
        .get();

    if (upcoming.docs.isEmpty) return;
    final token = ActiveToken.fromFirestore(upcoming.docs.first);

    await _notifications.createNotification(
      userId: token.customerId,
      title: 'Almost Your Turn',
      body: 'Only 1 person ahead. Token #${token.tokenNumber}.',
      type: NotificationType.turnSoon,
      shopId: shopId,
      requestId: token.requestId,
    );
  }
}
