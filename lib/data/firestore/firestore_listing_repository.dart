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
    String? winnerUserId,
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

    if (winnerUserId != null && winnerUserId.isNotEmpty) {
      update['winnerUserId'] = winnerUserId;
    }

    return _col.doc(listingId).update(update);
  }

  @override
  Future<void> buyoutListing({
    required String listingId,
    required String buyerId,
    required int boughtAtMillis,
  }) async {
    if (buyerId.isEmpty) {
      throw StateError('You must be signed in.');
    }

    final listingRef = _col.doc(listingId);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(listingRef);
        if (!snap.exists) {
          throw StateError('Listing not found.');
        }
        final data = snap.data();
        if (data == null) {
          throw StateError('Listing not found.');
        }

        final sellerId = _readString(data, 'sellerId');
        final isClosed = _readBoolOrDefault(
          data['isClosed'],
          defaultValue: false,
        );
        final closingTimeMillis = _readInt(data, 'closingTimeMillis');
        final buyOutPrice = _readDouble(data, 'buyOutPrice');
        final currentBid = _readDoubleNullable(data['currentBid']);

        if (sellerId == buyerId) {
          throw StateError("You can't buy out your own listing.");
        }
        if (isClosed) {
          throw StateError('Listing already closed.');
        }
        if (boughtAtMillis >= closingTimeMillis) {
          // UX requirement: prevent late buyouts.
          throw StateError('Buyout period has ended.');
        }
        if (currentBid != null && currentBid >= buyOutPrice) {
          throw StateError(
            'Buyout unavailable: current bid meets buyout price.',
          );
        }

        tx.update(listingRef, <String, dynamic>{
          'isClosed': true,
          'closedAtMillis': boughtAtMillis,
          'hasBid': true,
          'currentBid': buyOutPrice,
          'currentBidderId': buyerId,
          'closingBid': buyOutPrice,
          'winnerUserId': buyerId,
        });
      });
    } on FirebaseException catch (e) {
      final msg = e.message;
      throw StateError(
        msg == null || msg.isEmpty
            ? 'Firestore error (${e.code})'
            : 'Firestore error (${e.code}): $msg',
      );
    }
  }

  @override
  Future<void> autoCloseExpiredListing({required String listingId}) async {
    final listingRef = _col.doc(listingId);
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(listingRef);
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;

        final isClosed = _readBoolOrDefault(
          data['isClosed'],
          defaultValue: false,
        );
        if (isClosed) return;

        final closingTimeMillis = _readInt(data, 'closingTimeMillis');
        if (now < closingTimeMillis) {
          // Avoid generating permission-denied writes before expiry.
          return;
        }

        final hasBid = _readBoolOrDefault(data['hasBid'], defaultValue: false);
        final currentBid = _readDoubleNullable(data['currentBid']);
        final currentBidderId = data['currentBidderId'] as String?;

        final update = <String, dynamic>{
          'isClosed': true,
          // Deterministic close time: use the listing's own closing time.
          'closedAtMillis': closingTimeMillis,
        };

        if (hasBid && currentBid != null && currentBidderId != null) {
          update['closingBid'] = currentBid;
          update['winnerUserId'] = currentBidderId;
        }

        tx.update(listingRef, update);
      });
    } on FirebaseException catch (e) {
      final msg = e.message;
      throw StateError(
        msg == null || msg.isEmpty
            ? 'Firestore error (${e.code})'
            : 'Firestore error (${e.code}): $msg',
      );
    }
  }
}

String _readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw StateError('Invalid listing data: "$key" is missing.');
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw StateError('Invalid listing data: "$key" is missing.');
}

double _readDouble(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  throw StateError('Invalid listing data: "$key" is missing.');
}

double? _readDoubleNullable(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return null;
}

bool _readBoolOrDefault(Object? value, {required bool defaultValue}) {
  if (value is bool) return value;
  return defaultValue;
}
