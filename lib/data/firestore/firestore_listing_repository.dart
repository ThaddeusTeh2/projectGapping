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
    // Day 6 pivot improvement: use a stable server-side query shape that matches
    // our planned composite index, and keep the remaining filters local.
    //
    // If the index is missing, Firestore will throw FAILED_PRECONDITION with a
    // console URL that can be clicked to create the index.
    final query = _col
        .where('isClosed', isEqualTo: isClosed)
        .orderBy('dateCreatedMillis', descending: true)
        .limit(limit);

    final snapshot = await query.get();
    final all = snapshot.docs
        .map((doc) => ShopListing.fromFirestore(id: doc.id, data: doc.data()))
        .toList(growable: false);

    // Apply simple local filters so the API contract remains truthful.
    Iterable<ShopListing> filtered = all;
    if (brandKey != null) {
      filtered = filtered.where((l) => l.brandKey == brandKey);
    }
    if (category != null) {
      filtered = filtered.where((l) => l.category == category);
    }
    if (displacementBucket != null) {
      filtered = filtered.where(
        (l) => l.displacementBucket == displacementBucket,
      );
    }

    return filtered.toList(growable: false);
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
    double? closingBid,
  }) {
    final update = <String, dynamic>{
      'isClosed': true,
      'closedAtMillis': closedAtMillis,
    };

    // Some security rules require `closingBid` to be absent unless it's a real
    // number matching the existing `currentBid`.
    if (closingBid != null) {
      update['closingBid'] = closingBid;
    }

    return _col.doc(listingId).update(update);
  }
}
