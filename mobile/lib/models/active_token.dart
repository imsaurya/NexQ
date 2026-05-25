import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ActiveToken extends Equatable {
  const ActiveToken({
    required this.id,
    required this.shopId,
    required this.requestId,
    required this.customerId,
    required this.customerName,
    required this.tokenNumber,
    required this.serviceName,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.isServing = false,
    this.isDelayed = false,
  });

  final String id;
  final String shopId;
  final String requestId;
  final String customerId;
  final String customerName;
  final int tokenNumber;
  final String serviceName;
  final int position;
  final bool isServing;
  final bool isDelayed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'requestId': requestId,
      'customerId': customerId,
      'customerName': customerName,
      'tokenNumber': tokenNumber,
      'serviceName': serviceName,
      'position': position,
      'isServing': isServing,
      'isDelayed': isDelayed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ActiveToken.fromMap(Map<String, dynamic> map) {
    return ActiveToken(
      id: map['id'] as String,
      shopId: map['shopId'] as String,
      requestId: map['requestId'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String? ?? 'Customer',
      tokenNumber: map['tokenNumber'] as int,
      serviceName: map['serviceName'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      isServing: map['isServing'] as bool? ?? false,
      isDelayed: map['isDelayed'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ActiveToken.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ActiveToken.fromMap({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, tokenNumber, position, isServing];
}
