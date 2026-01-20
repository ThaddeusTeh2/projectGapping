// BikeComment domain model.
// Firestore: comments/{commentId}
// Fields: bikeId, userId, commentTitle, comment, tags?, upvoteCount, downvoteCount, dateCreatedMillis
// Includes: fromFirestore/toFirestore

class BikeComment {
  const BikeComment({
    required this.id,
    required this.bikeId,
    required this.userId,
    required this.commentTitle,
    required this.comment,
    required this.tags,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.dateCreatedMillis,
  });

  final String id;
  final String bikeId;
  final String userId;
  final String commentTitle;
  final String comment;
  final List<String> tags;
  final int upvoteCount;
  final int downvoteCount;
  final int dateCreatedMillis;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'bikeId': bikeId,
      'userId': userId,
      'commentTitle': commentTitle,
      'comment': comment,
      if (tags.isNotEmpty) 'tags': tags,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'dateCreatedMillis': dateCreatedMillis,
    };
  }

  factory BikeComment.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return BikeComment(
      id: id,
      bikeId: _readString(data, 'bikeId'),
      userId: _readString(data, 'userId'),
      commentTitle: _readString(data, 'commentTitle'),
      comment: _readString(data, 'comment'),
      tags: _readStringList(data['tags']),
      upvoteCount: _readIntOrDefault(data['upvoteCount'], defaultValue: 0),
      downvoteCount: _readIntOrDefault(data['downvoteCount'], defaultValue: 0),
      dateCreatedMillis: _readInt(data, 'dateCreatedMillis'),
    );
  }
}

String _readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw FormatException(
    'Expected "$key" to be a String, got ${value.runtimeType}',
  );
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'Expected "$key" to be a number, got ${value.runtimeType}',
  );
}

int _readIntOrDefault(Object? value, {required int defaultValue}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return defaultValue;
}

List<String> _readStringList(Object? value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
