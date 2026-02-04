// PublicUser domain model.
// Firestore: public_users/{userId}
// Public fields only: displayName (+ updatedAtMillis).

class PublicUser {
  const PublicUser({
    required this.id,
    required this.displayName,
    required this.updatedAtMillis,
  });

  final String id;
  final String displayName;
  final int updatedAtMillis;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'displayName': displayName,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory PublicUser.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PublicUser(
      id: id,
      displayName: _readStringOrDefault(data['displayName'], defaultValue: ''),
      updatedAtMillis: _readIntOrDefault(
        data['updatedAtMillis'],
        defaultValue: 0,
      ),
    );
  }
}

String _readStringOrDefault(Object? value, {required String defaultValue}) {
  if (value is String) return value;
  return defaultValue;
}

int _readIntOrDefault(Object? value, {required int defaultValue}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return defaultValue;
}
