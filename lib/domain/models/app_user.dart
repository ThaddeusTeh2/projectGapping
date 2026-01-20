// AppUser domain model.
// Firestore: users/{userId}
// Minimal fields per SSOT: userDateCreatedMillis
// Includes: fromFirestore/toFirestore

class AppUser {
  const AppUser({required this.id, required this.userDateCreatedMillis});

  final String id;
  final int userDateCreatedMillis;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{'userDateCreatedMillis': userDateCreatedMillis};
  }

  factory AppUser.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return AppUser(
      id: id,
      userDateCreatedMillis: _readInt(data, 'userDateCreatedMillis'),
    );
  }
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'Expected "$key" to be a number, got ${value.runtimeType}',
  );
}
