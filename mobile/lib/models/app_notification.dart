import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  requestApproved,
  requestRejected,
  turnSoon,
  queuePaused,
  tokenSkipped,
  general,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.shopId,
    this.requestId,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? shopId;
  final String? requestId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'shopId': shopId,
      'requestId': requestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      shopId: map['shopId'] as String?,
      requestId: map['requestId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification.fromMap({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, isRead, createdAt];
}
