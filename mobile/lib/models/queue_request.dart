import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum QueueRequestStatus {
  pending,
  approved,
  rejected,
  delayed,
  cancelled,
  completed,
}

class QueueRequest extends Equatable {
  const QueueRequest({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.serviceId,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tokenNumber,
    this.preferredTime,
    this.note,
    this.delayMinutes = 0,
    this.peopleAhead = 0,
  });

  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final String serviceId;
  final String serviceName;
  final QueueRequestStatus status;
  final int? tokenNumber;
  final String? preferredTime;
  final String? note;
  final int delayMinutes;
  final int peopleAhead;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == QueueRequestStatus.pending ||
      status == QueueRequestStatus.approved ||
      status == QueueRequestStatus.delayed;

  QueueRequest copyWith({
    String? id,
    String? shopId,
    String? customerId,
    String? customerName,
    String? serviceId,
    String? serviceName,
    QueueRequestStatus? status,
    int? tokenNumber,
    String? preferredTime,
    String? note,
    int? delayMinutes,
    int? peopleAhead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueueRequest(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      preferredTime: preferredTime ?? this.preferredTime,
      note: note ?? this.note,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      peopleAhead: peopleAhead ?? this.peopleAhead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'customerId': customerId,
      'customerName': customerName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'status': status.name,
      'tokenNumber': tokenNumber,
      'preferredTime': preferredTime,
      'note': note,
      'delayMinutes': delayMinutes,
      'peopleAhead': peopleAhead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory QueueRequest.fromMap(Map<String, dynamic> map) {
    return QueueRequest(
      id: map['id'] as String,
      shopId: map['shopId'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String? ?? 'Customer',
      serviceId: map['serviceId'] as String,
      serviceName: map['serviceName'] as String? ?? '',
      status: QueueRequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => QueueRequestStatus.pending,
      ),
      tokenNumber: map['tokenNumber'] as int?,
      preferredTime: map['preferredTime'] as String?,
      note: map['note'] as String?,
      delayMinutes: map['delayMinutes'] as int? ?? 0,
      peopleAhead: map['peopleAhead'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory QueueRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return QueueRequest.fromMap({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, status, tokenNumber, updatedAt];
}
