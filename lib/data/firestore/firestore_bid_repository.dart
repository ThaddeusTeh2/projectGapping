// Firestore-backed BidRepository implementation.
//
// Spark-plan Day 6 pivot: place bids using a Firestore transaction.
// This keeps the repo boundary intact and gives the demo “real” bid behavior
// without requiring Cloud Functions.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../repositories/bid_repository.dart';
import 'firestore_paths.dart';

// Debug-only probe to pinpoint whether PERMISSION_DENIED is coming from
// `bids/{bidId}` create or `listings/{listingId}` update.
//
// If enabled and the main transaction hits permission-denied, the repo will
// attempt a *standalone* bid create and log whether it succeeds.
//
// NOTE: If the probe succeeds, it creates an orphan bid doc (because the main
// transaction still failed). You can delete that doc in Firebase Console.
const bool _kEnablePermissionProbe = kDebugMode;
final Set<String> _permissionProbeRanForListingIds = <String>{};

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

        tx.set(bidRef, <String, dynamic>{
          'listingId': listingId,
          'bidderId': user.uid,
          'amount': amount,
          'dateCreatedMillis': nowMillis,
        });

        tx.update(listingRef, <String, dynamic>{
          'currentBid': amount,
          'hasBid': true,
        });
      });
    } on FirebaseException catch (e) {
      // Make permission/index/rule failures visible in UI.
      final msg = e.message;
      if (e.code == 'permission-denied') {
        debugPrint(
          'placeBid permission-denied: projectId=${Firebase.app().options.projectId} uid=${user.uid} listingId=$listingId',
        );

        if (kDebugMode &&
            _kEnablePermissionProbe &&
            !_permissionProbeRanForListingIds.contains(listingId)) {
          _permissionProbeRanForListingIds.add(listingId);
          await _probeBidCreateOnly(
            firestore: _firestore,
            listingId: listingId,
            uid: user.uid,
            amount: amount,
          );
        }
      }
      throw StateError(
        msg == null || msg.isEmpty
            ? 'Firestore error (${e.code})'
            : 'Firestore error (${e.code}): $msg',
      );
    }
  }
}

Future<void> _probeBidCreateOnly({
  required FirebaseFirestore firestore,
  required String listingId,
  required String uid,
  required double amount,
}) async {
  final ref = firestore.collection(FirestorePaths.bids).doc();
  final nowMillis = DateTime.now().millisecondsSinceEpoch;

  try {
    await ref.set(<String, dynamic>{
      'listingId': listingId,
      'bidderId': uid,
      'amount': amount,
      'dateCreatedMillis': nowMillis,
    });
    debugPrint(
      'PERMISSION PROBE: bids create SUCCEEDED (bidId=${ref.id}). Listing update rule likely denied. Delete this orphan bid in Console if desired.',
    );
  } on FirebaseException catch (e) {
    debugPrint(
      'PERMISSION PROBE: bids create FAILED (${e.code}): ${e.message}',
    );
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
