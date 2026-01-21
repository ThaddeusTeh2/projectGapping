// Firestore-backed BikeRepository implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/bike.dart';
import '../repositories/bike_repository.dart';
import 'firestore_paths.dart';

class FirestoreBikeRepository implements BikeRepository {
  FirestoreBikeRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.motorcycles);

  @override
  Future<List<Bike>> listBikes({
    String? brandKey,
    String? category,
    String? displacementBucket,
    BikeSort sort = BikeSort.titleAsc,
    int limit = 50,
  }) async {
    // Intentionally do not apply Firestore-side filtering/sorting.
    // This avoids composite index explosion. The app filters/sorts locally.
    final snapshot = await _col.limit(limit).get();
    return snapshot.docs
        .map((doc) => Bike.fromFirestore(id: doc.id, data: doc.data()))
        .toList(growable: false);
  }

  @override
  Future<Bike?> getBikeById(String bikeId) async {
    final doc = await _col.doc(bikeId).get();
    final data = doc.data();
    if (data == null) return null;
    return Bike.fromFirestore(id: doc.id, data: data);
  }
}
