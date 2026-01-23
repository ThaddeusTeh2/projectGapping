// Listing repository interface.
// Responsibility: listing list/get/create/close.

import '../../domain/models/shop_listing.dart';

abstract class ListingRepository {
  Future<List<ShopListing>> listListings({
    bool isClosed = false,
    String? brandKey,
    String? category,
    String? displacementBucket,
    int limit = 50,
  });

  Future<ShopListing?> getListingById(String listingId);

  Future<String> createListing(ShopListing listing);

  Future<void> closeListing({
    required String listingId,
    required int closedAtMillis,
    double? closingBid,
  });
}
