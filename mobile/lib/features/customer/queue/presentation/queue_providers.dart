import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/queue_request.dart';

final queueRequestProvider = StreamProvider.family<QueueRequest?, String>((ref, requestId) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.queueRequests)
      .doc(requestId)
      .snapshots()
      .map((doc) => doc.exists ? QueueRequest.fromFirestore(doc) : null);
});
