import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ShopStatus { open, closed, paused }

enum ShopApprovalStatus { pending, approved, rejected, banned }

class ShopService extends Equatable {
  const ShopService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final double price;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
      };

  factory ShopService.fromMap(Map<String, dynamic> map) {
    return ShopService(
      id: map['id'] as String,
      name: map['name'] as String,
      durationMinutes: map['durationMinutes'] as int? ?? 15,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ShopTimings extends Equatable {
  const ShopTimings({
    required this.openTime,
    required this.closeTime,
    required this.workingDays,
  });

  final String openTime;
  final String closeTime;
  final List<int> workingDays;

  Map<String, dynamic> toMap() => {
        'openTime': openTime,
        'closeTime': closeTime,
        'workingDays': workingDays,
      };

  factory ShopTimings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ShopTimings(
        openTime: '09:00',
        closeTime: '21:00',
        workingDays: [1, 2, 3, 4, 5, 6],
      );
    }
    return ShopTimings(
      openTime: map['openTime'] as String? ?? '09:00',
      closeTime: map['closeTime'] as String? ?? '21:00',
      workingDays: List<int>.from(map['workingDays'] ?? [1, 2, 3, 4, 5, 6]),
    );
  }

  @override
  List<Object?> get props => [openTime, closeTime, workingDays];
}

class Shop extends Equatable {
  const Shop({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.ownerId,
    required this.city,
    required this.area,
    required this.address,
    required this.timings,
    required this.services,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
    this.status = ShopStatus.closed,
    this.approvalStatus = ShopApprovalStatus.pending,
    this.currentToken = 0,
    this.servingToken = 0,
    this.queuePaused = false,
    this.waitingCount = 0,
    this.avgWaitMinutes = 15,
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String ownerId;
  final String city;
  final String area;
  final String address;
  final ShopTimings timings;
  final List<ShopService> services;
  final List<String> imageUrls;
  final ShopStatus status;
  final ShopApprovalStatus approvalStatus;
  final int currentToken;
  final int servingToken;
  final bool queuePaused;
  final int waitingCount;
  final int avgWaitMinutes;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == ShopStatus.open && !queuePaused;

  String get crowdLevel {
    if (waitingCount <= 2) return 'Low';
    if (waitingCount <= 3) return 'Medium';
    return 'High';
  }

  Shop copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? ownerId,
    String? city,
    String? area,
    String? address,
    ShopTimings? timings,
    List<ShopService>? services,
    List<String>? imageUrls,
    ShopStatus? status,
    ShopApprovalStatus? approvalStatus,
    int? currentToken,
    int? servingToken,
    bool? queuePaused,
    int? waitingCount,
    int? avgWaitMinutes,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      ownerId: ownerId ?? this.ownerId,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      timings: timings ?? this.timings,
      services: services ?? this.services,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      currentToken: currentToken ?? this.currentToken,
      servingToken: servingToken ?? this.servingToken,
      queuePaused: queuePaused ?? this.queuePaused,
      waitingCount: waitingCount ?? this.waitingCount,
      avgWaitMinutes: avgWaitMinutes ?? this.avgWaitMinutes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'ownerId': ownerId,
      'city': city,
      'area': area,
      'address': address,
      'timings': timings.toMap(),
      'services': services.map((s) => s.toMap()).toList(),
      'imageUrls': imageUrls,
      'status': status.name,
      'approvalStatus': approvalStatus.name,
      'currentToken': currentToken,
      'servingToken': servingToken,
      'queuePaused': queuePaused,
      'waitingCount': waitingCount,
      'avgWaitMinutes': avgWaitMinutes,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      ownerId: map['ownerId'] as String,
      city: map['city'] as String,
      area: map['area'] as String,
      address: map['address'] as String? ?? '',
      timings: ShopTimings.fromMap(map['timings'] as Map<String, dynamic>?),
      services: (map['services'] as List<dynamic>? ?? [])
          .map((e) => ShopService.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: ShopStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ShopStatus.closed,
      ),
      approvalStatus: ShopApprovalStatus.values.firstWhere(
        (s) => s.name == map['approvalStatus'],
        orElse: () => ShopApprovalStatus.pending,
      ),
      currentToken: map['currentToken'] as int? ?? 0,
      servingToken: map['servingToken'] as int? ?? 0,
      queuePaused: map['queuePaused'] as bool? ?? false,
      waitingCount: map['waitingCount'] as int? ?? 0,
      avgWaitMinutes: map['avgWaitMinutes'] as int? ?? 15,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Shop.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Shop.fromMap({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, name, status, waitingCount, updatedAt];
}
