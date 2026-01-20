// Bid repository interface.
// Responsibility: bid placement via callable function.

abstract class BidRepository {
  Future<void> placeBid({required String listingId, required double amount});
}
