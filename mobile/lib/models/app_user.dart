import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/user_roles.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.phone,
    this.fcmToken,
    this.savedShopIds = const [],
    this.isActive = true,
  });

  /// Same as [id] — matches Firestore `uid` field.
  String get uid => id;

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final UserRole role;
  final String? fcmToken;
  final List<String> savedShopIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    UserRole? role,
    String? fcmToken,
    List<String>? savedShopIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      savedShopIds: savedShopIds ?? this.savedShopIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'role': role.value,
      'fcmToken': fcmToken,
      'savedShopIds': savedShopIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Minimal map for first-time profile creation (matches security rules).
  Map<String, dynamic> toCreateMap() {
    return {
      'uid': id,
      'id': id,
      'email': email,
      'role': role.value,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': true,
      'savedShopIds': <String>[],
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final id = (map['uid'] as String?) ??
        (map['id'] as String?) ??
        documentId ??
        '';

    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      fcmToken: map['fcmToken'] as String?,
      savedShopIds: List<String>.from(map['savedShopIds'] ?? []),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser.fromMap(data, documentId: doc.id);
  }

  @override
  List<Object?> get props => [id, email, role, updatedAt];
}
