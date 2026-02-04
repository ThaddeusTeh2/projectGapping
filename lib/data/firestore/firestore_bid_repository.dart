// Firestore-backed BidRepository implementation.
//
// Places bids by updating the listing doc directly:
// - listings/{listingId}.currentBid
// - listings/{listingId}.hasBid
// - listings/{listingId}.currentBidderId
//
// Also writes a bid-history record:
// - bids/{bidId}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../repositories/bid_repository.dart';
import 'firestore_paths.dart';

class FirestoreBidRepository implements BidRepository {
  FirestoreBidRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> placeBid({
    required String listingId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to place a bid.');
    }

    debugPrint(
      'placeBid start: projectId=${Firebase.app().options.projectId} uid=${user.uid} listingId=$listingId amount=$amount',
    );

    if (amount.isNaN || amount.isInfinite || amount <= 0) {
      throw StateError('Bid amount must be greater than 0.');
    }

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final listingRef = _firestore
        .collection(FirestorePaths.listings)
        .doc(listingId);
    final bidRef = _firestore.collection(FirestorePaths.bids).doc();

    try {
      await _firestore.runTransaction((tx) async {
        final listingSnap = await tx.get(listingRef);
        if (!listingSnap.exists) {
          throw StateError('Listing not found.');
        }

        final data = listingSnap.data();
        if (data == null) {
          throw StateError('Listing not found.');
        }

        final sellerId = _readString(data, 'sellerId');
        final isClosed = _readBoolOrDefault(
          data['isClosed'],
          defaultValue: false,
        );
        final closingTimeMillis = _readInt(data, 'closingTimeMillis');
        final startingBid = _readDouble(data, 'startingBid');
        final currentBid = _readDoubleNullable(data['currentBid']);

        if (sellerId == user.uid) {
          throw StateError("You can't bid on your own listing.");
        }

        if (isClosed) {
          throw StateError('Listing already closed.');
        }

        if (nowMillis >= closingTimeMillis) {
          throw StateError('Bidding has ended.');
        }

        if (currentBid != null) {
          if (amount <= currentBid) {
            throw StateError('Bid must be higher than current bid.');
          }
        } else {
          if (amount < startingBid) {
            throw StateError('Bid must be at least the starting bid.');
          }
        }

        tx.update(listingRef, <String, dynamic>{
          'currentBid': amount,
          'hasBid': true,
          'currentBidderId': user.uid,
        });

        tx.set(bidRef, <String, dynamic>{
          'listingId': listingId,
          'bidderId': user.uid,
          'amount': amount,
          'dateCreatedMillis': nowMillis,
        });
      });
    } on FirebaseException catch (e) {
      // Make permission/index/rule failures visible in UI.
      final msg = e.message;
      if (e.code == 'permission-denied') {
        debugPrint(
          'placeBid permission-denied: projectId=${Firebase.app().options.projectId} uid=${user.uid} listingId=$listingId',
        );
      }
      throw StateError(
        msg == null || msg.isEmpty
            ? 'Firestore error (${e.code})'
            : 'Firestore error (${e.code}): $msg',
      );
    }
  }
}

String _readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw StateError('Invalid listing data: "$key" is missing.');
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw StateError('Invalid listing data: "$key" is missing.');
}

double _readDouble(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  throw StateError('Invalid listing data: "$key" is missing.');
}

double? _readDoubleNullable(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return null;
}

bool _readBoolOrDefault(Object? value, {required bool defaultValue}) {
  if (value is bool) return value;
  return defaultValue;
}
