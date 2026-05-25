import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_collections.dart';
import '../core/errors/app_exception.dart';
import '../models/shop.dart';

class ShopRepository {
  ShopRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestoreCollections.shops);

  Stream<Shop?> watchShop(String shopId) {
    return _shops.doc(shopId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Shop.fromFirestore(doc);
    });
  }

  Future<Shop?> getShop(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    if (!doc.exists) return null;
    return Shop.fromFirestore(doc);
  }

  Stream<List<Shop>> watchShops({
    required String city,
    String? area,
    String? categoryId,
    String? searchQuery,
  }) {
    print('DEBUG watchShops: city=$city area=$area');

    var query = _shops
        .where('city', isEqualTo: city)
        .where('approvalStatus', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      print('DEBUG snapshot docs: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        print('DEBUG doc: ${doc.id} data=${doc.data()}');
      }

      var shops = snapshot.docs.map((doc) {
        try {
          return Shop.fromFirestore(doc);
        } catch (e) {
          print('DEBUG Shop.fromFirestore error: $e for doc ${doc.id}');
          return null;
        }
      }).whereType<Shop>().toList();

      print('DEBUG parsed shops: ${shops.length}');
      return shops;
    });
  }

  Future<List<Shop>> getOwnerShops(String ownerId) async {
    final snapshot = await _shops
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map(Shop.fromFirestore).toList();
  }

  Future<Shop> createShop({
    required String ownerId,
    required String name,
    required String categoryId,
    required String categoryName,
    required String city,
    required String area,
    required String address,
    required ShopTimings timings,
    required List<ShopService> services,
    List<String> imageUrls = const [],
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final shop = Shop(
      id: id,
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      ownerId: ownerId,
      city: city,
      area: area,
      address: address,
      timings: timings,
      services: services,
      imageUrls: imageUrls,
      status: ShopStatus.closed,
      approvalStatus: ShopApprovalStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _shops.doc(id).set(shop.toMap());
    return shop;
  }

  Future<void> updateShop(Shop shop) async {
    await _shops.doc(shop.id).update(
          shop.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<String> uploadShopImage(String shopId, String filePath) async {
    final ref = _storage.ref().child('shops/$shopId/${_uuid.v4()}.jpg');
    await ref.putString(filePath);
    return ref.getDownloadURL();
  }

  Future<void> updateShopStatus(String shopId, ShopStatus status) async {
    await _shops.doc(shopId).update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> setQueuePaused(String shopId, bool paused) async {
    await _shops.doc(shopId).update({
      'queuePaused': paused,
      'status': paused ? ShopStatus.paused.name : ShopStatus.open.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<Shop>> watchShopsByStatus(String status) {
    return _shops
        .where('approvalStatus', isEqualTo: status)
        .snapshots()
        .map((s) => s.docs.map(Shop.fromFirestore).toList());
  }

  Stream<List<Shop>> watchAllShops() {
    return _shops
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Shop.fromFirestore).toList());
  }

  Future<void> updateShopApproval(String shopId, String status) async {
    await _shops.doc(shopId).update({
      'approvalStatus': status,
      'isActive': status == 'approved',
      'updatedAt': Timestamp.now(),
    });
  }
}
