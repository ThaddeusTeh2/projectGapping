// Bid repository interface.
// Responsibility: bid placement via repository boundary.
//
// Day 6 (Spark-plan pivot): bid placement is implemented using a Firestore
// transaction (client-side). This provides good UX correctness for the demo,
// but is not equivalent to server-side enforcement.

abstract class BidRepository {
  Future<void> placeBid({required String listingId, required double amount});
}
