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

  // Public profile surface (public_users/{userId}).
  Future<String?> getPublicDisplayName(String userId);
  Stream<String?> watchPublicDisplayName(String userId);
  Future<void> ensurePublicUserDoc({
    required String userId,
    required String defaultDisplayName,
    required int updatedAtMillis,
  });
  Future<void> setPublicDisplayName({
    required String userId,
    required String displayName,
    required int updatedAtMillis,
  });

  Future<List<ShopListing>> listMyListings(String userId, {int limit = 50});
  Future<List<Bid>> listMyBids(String userId, {int limit = 50});
}
