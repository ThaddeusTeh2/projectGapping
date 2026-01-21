// Firestore-backed UserRepository implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/bid.dart';
import '../../domain/models/shop_listing.dart';
import '../repositories/user_repository.dart';
import 'firestore_paths.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);
  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection(FirestorePaths.listings);
  CollectionReference<Map<String, dynamic>> get _bids =>
      _firestore.collection(FirestorePaths.bids);

  @override
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _users.doc(userId).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromFirestore(id: doc.id, data: data);
  }

  @override
  Future<void> ensureUserDoc({
    required String userId,
    required int userDateCreatedMillis,
  }) async {
    await _users
        .doc(userId)
        .set(
          AppUser(
            id: userId,
            userDateCreatedMillis: userDateCreatedMillis,
          ).toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<List<ShopListing>> listMyListings(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _listings
        .where('sellerId', isEqualTo: userId)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ShopListing.fromFirestore(id: doc.id, data: doc.data()))
        .toList(growable: false);
  }

  @override
  Future<List<Bid>> listMyBids(String userId, {int limit = 50}) async {
    final snapshot = await _bids
        .where('bidderId', isEqualTo: userId)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => Bid.fromFirestore(id: doc.id, data: doc.data()))
        .toList(growable: false);
  }
}
