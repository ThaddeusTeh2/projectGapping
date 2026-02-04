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
  CollectionReference<Map<String, dynamic>> get _publicUsers =>
      _firestore.collection(FirestorePaths.publicUsers);
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
  Future<String?> getPublicDisplayName(String userId) async {
    final doc = await _publicUsers.doc(userId).get();
    final data = doc.data();
    if (data == null) return null;
    final value = data['displayName'];
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  @override
  Stream<String?> watchPublicDisplayName(String userId) {
    return _publicUsers.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final value = data['displayName'];
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      return null;
    });
  }

  @override
  Future<void> ensurePublicUserDoc({
    required String userId,
    required String defaultDisplayName,
    required int updatedAtMillis,
  }) async {
    final ref = _publicUsers.doc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(<String, dynamic>{
        'displayName': defaultDisplayName.trim(),
        'updatedAtMillis': updatedAtMillis,
      });
      return;
    }

    final data = snap.data();
    final existing = data == null ? null : data['displayName'];
    final existingName = existing is String ? existing.trim() : '';
    if (existingName.isNotEmpty) return;

    await ref.set(<String, dynamic>{
      'displayName': defaultDisplayName.trim(),
      'updatedAtMillis': updatedAtMillis,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setPublicDisplayName({
    required String userId,
    required String displayName,
    required int updatedAtMillis,
  }) async {
    await _publicUsers.doc(userId).set(<String, dynamic>{
      'displayName': displayName.trim(),
      'updatedAtMillis': updatedAtMillis,
    }, SetOptions(merge: true));
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
