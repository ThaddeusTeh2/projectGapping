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
    await callable.call(<String, dynamic>{
      'listingId': listingId,
      'amount': amount,
    });
  }
}
