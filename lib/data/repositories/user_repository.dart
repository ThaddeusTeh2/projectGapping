// User repository interface.
// Responsibility: profile read + my lists.

import '../../domain/models/app_user.dart';
import '../../domain/models/bid.dart';
import '../../domain/models/shop_listing.dart';

abstract class UserRepository {
  Future<AppUser?> getUserById(String userId);
  Future<void> ensureUserDoc({
    required String userId,
    required int userDateCreatedMillis,
  });

  Future<List<ShopListing>> listMyListings(String userId, {int limit = 50});
  Future<List<Bid>> listMyBids(String userId, {int limit = 50});
}
