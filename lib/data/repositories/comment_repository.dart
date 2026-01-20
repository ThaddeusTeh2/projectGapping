// Comment repository interface.
// Responsibility: comment list/add/vote.

import '../../domain/models/bike_comment.dart';

abstract class CommentRepository {
  Stream<List<BikeComment>> watchCommentsForBike(
    String bikeId, {
    int limit = 50,
  });

  Future<String> addComment({
    required String bikeId,
    required String userId,
    required String commentTitle,
    required String comment,
    List<String> tags = const <String>[],
    required int dateCreatedMillis,
  });

  Future<void> upvoteComment(String commentId);
  Future<void> downvoteComment(String commentId);
}
