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

  @override
  Stream<List<BikeComment>> watchCommentsForBike(
    String bikeId, {
    int limit = 50,
  }) {
    return _col
        .where('bikeId', isEqualTo: bikeId)
        .orderBy('dateCreatedMillis', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    BikeComment.fromFirestore(id: doc.id, data: doc.data()),
              )
              .toList(growable: false),
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
  Future<void> upvoteComment(String commentId) {
    return _col.doc(commentId).update(<String, dynamic>{
      'upvoteCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> downvoteComment(String commentId) {
    return _col.doc(commentId).update(<String, dynamic>{
      'downvoteCount': FieldValue.increment(1),
    });
  }
}
