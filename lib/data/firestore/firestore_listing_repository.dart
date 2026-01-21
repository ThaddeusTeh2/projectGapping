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
    // Intentionally fetch broad and sort/filter locally in the app.
    // Multi-field filters + orderBy quickly require many composite indexes.
    final snapshot = await _col.limit(limit).get();
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
