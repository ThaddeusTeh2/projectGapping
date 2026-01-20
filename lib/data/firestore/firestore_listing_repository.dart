// Firestore-backed ListingRepository implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/shop_listing.dart';
import '../repositories/listing_repository.dart';
import 'firestore_paths.dart';

class FirestoreListingRepository implements ListingRepository {
  FirestoreListingRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.listings);

  @override
  Future<List<ShopListing>> listListings({
    bool isClosed = false,
    String? brandKey,
    String? category,
    String? displacementBucket,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _col.where(
      'isClosed',
      isEqualTo: isClosed,
    );

    if (brandKey != null && brandKey.isNotEmpty) {
      query = query.where('brandKey', isEqualTo: brandKey);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (displacementBucket != null && displacementBucket.isNotEmpty) {
      query = query.where('displacementBucket', isEqualTo: displacementBucket);
    }

    query = query.orderBy('dateCreatedMillis', descending: true);

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => ShopListing.fromFirestore(id: doc.id, data: doc.data()))
        .toList(growable: false);
  }

  @override
  Future<ShopListing?> getListingById(String listingId) async {
    final doc = await _col.doc(listingId).get();
    final data = doc.data();
    if (data == null) return null;
    return ShopListing.fromFirestore(id: doc.id, data: data);
  }

  @override
  Future<String> createListing(ShopListing listing) async {
    final doc = _col.doc();
    await doc.set(listing.toFirestore());
    return doc.id;
  }

  @override
  Future<void> closeListing({
    required String listingId,
    required int closedAtMillis,
  }) {
    return _col.doc(listingId).update(<String, dynamic>{
      'isClosed': true,
      'closedAtMillis': closedAtMillis,
    });
  }
}
