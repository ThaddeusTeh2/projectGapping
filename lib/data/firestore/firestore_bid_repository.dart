// FirebaseFunctions-backed BidRepository implementation.

import 'package:cloud_functions/cloud_functions.dart';

import '../repositories/bid_repository.dart';

class FirestoreBidRepository implements BidRepository {
  FirestoreBidRepository({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<void> placeBid({
    required String listingId,
    required double amount,
  }) async {
    final callable = _functions.httpsCallable('placeBid');
    try {
      await callable.call(<String, dynamic>{
        'listingId': listingId,
        'amount': amount,
      });
    } on FirebaseFunctionsException catch (e) {
      // SSOT UX: surface server messages from the callable.
      // Day 6 adds the real function; until then, this still produces a useful error.
      final message = e.message ?? 'Failed to place bid';
      throw StateError(message);
    }
  }
}
