// Bike repository interface.
// Responsibility: bike queries.

import '../../domain/models/bike.dart';

enum BikeSort { titleAsc, dateCreatedDesc, releaseYearDesc }

abstract class BikeRepository {
  Future<List<Bike>> listBikes({
    String? brandKey,
    String? category,
    String? displacementBucket,
    BikeSort sort = BikeSort.titleAsc,
    int limit = 50,
  });

  Future<Bike?> getBikeById(String bikeId);
}
