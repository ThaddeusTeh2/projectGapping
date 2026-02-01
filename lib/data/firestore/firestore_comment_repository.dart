// Firestore-backed CommentRepository implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/bike_comment.dart';
import '../repositories/comment_repository.dart';
import 'firestore_paths.dart';

class FirestoreCommentRepository implements CommentRepository {
  FirestoreCommentRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.comments);

    CollectionReference<Map<String, dynamic>> _votesCol(String commentId) =>
      _col.doc(commentId).collection('votes');

  @override
  Stream<List<BikeComment>> watchCommentsForBike(
    String bikeId, {
    int limit = 50,
  }) {
    return _col.where('bikeId', isEqualTo: bikeId).limit(limit).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map(
              (doc) => BikeComment.fromFirestore(id: doc.id, data: doc.data()),
            )
            .toList(growable: false);

        final sorted = List<BikeComment>.of(list);
        sorted.sort(
          (a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis),
        );
        return sorted;
      },
    );
  }

  @override
  Future<String> addComment({
    required String bikeId,
    required String userId,
    required String commentTitle,
    required String comment,
    List<String> tags = const <String>[],
    required int dateCreatedMillis,
  }) async {
    final doc = _col.doc();
    final model = BikeComment(
      id: doc.id,
      bikeId: bikeId,
      userId: userId,
      commentTitle: commentTitle,
      comment: comment,
      tags: tags,
      upvoteCount: 0,
      downvoteCount: 0,
      dateCreatedMillis: dateCreatedMillis,
    );
    await doc.set(model.toFirestore());
    return doc.id;
  }

  @override
  Future<void> upvoteComment({required String commentId, required String userId}) {
    return _vote(commentId: commentId, userId: userId, direction: 'up');
  }

  @override
  Future<void> downvoteComment({required String commentId, required String userId}) {
    return _vote(commentId: commentId, userId: userId, direction: 'down');
  }

  Future<void> _vote({
    required String commentId,
    required String userId,
    required String direction, // 'up' | 'down'
  }) async {
    if (userId.isEmpty) {
      throw StateError('You must be signed in to vote.');
    }
    if (direction != 'up' && direction != 'down') {
      throw StateError('Invalid vote direction.');
    }

    final commentRef = _col.doc(commentId);
    final voteRef = _votesCol(commentId).doc(userId);
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    try {
      await _firestore.runTransaction((tx) async {
        final voteSnap = await tx.get(voteRef);
        if (voteSnap.exists) {
          throw StateError('You have already voted on this comment.');
        }

        tx.set(voteRef, <String, dynamic>{
          'userId': userId,
          'direction': direction,
          'dateCreatedMillis': nowMillis,
        });

        tx.update(commentRef, <String, dynamic>{
          if (direction == 'up') 'upvoteCount': FieldValue.increment(1),
          if (direction == 'down') 'downvoteCount': FieldValue.increment(1),
        });
      });
    } on FirebaseException catch (e) {
      // Make rule failures readable.
      final msg = e.message;
      throw StateError(
        msg == null || msg.isEmpty
            ? 'Firestore error (${e.code})'
            : 'Firestore error (${e.code}): $msg',
      );
    }
  }
}
