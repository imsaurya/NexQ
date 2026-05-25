import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_collections.dart';
import '../models/category.dart';
import '../models/review.dart';

class CategoryRepository {
  CategoryRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestoreCollections.categories);

  Stream<List<Category>> watchCategories() {
    return _categories
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(Category.fromFirestore).toList());
  }

  Future<void> seedDefaultCategories() async {
    final snapshot = await _categories.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final defaults = [
      ('Salon', 'content_cut'),
      ('Clinic', 'medical_services'),
      ('Cafe', 'local_cafe'),
      ('Repair Shop', 'build'),
      ('Service Center', 'handyman'),
      ('Government Office', 'account_balance'),
    ];

    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (var i = 0; i < defaults.length; i++) {
      final (name, icon) = defaults[i];
      final id = name.toLowerCase().replaceAll(' ', '_');
      final ref = _categories.doc(id);
      batch.set(ref, {
        'id': id,
        'name': name,
        'iconName': icon,
        'sortOrder': i,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }
}

class ReviewRepository {
  ReviewRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreCollections.reviews);

  Stream<List<Review>> watchShopReviews(String shopId) {
    return _reviews
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.reviewsPageSize)
        .snapshots()
        .map((s) => s.docs.map(Review.fromFirestore).toList());
  }
}
