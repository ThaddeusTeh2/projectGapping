// Bid domain model.
// Firestore: bids/{bidId}
// Fields: listingId, bidderId, amount, dateCreatedMillis
// Note: client does not write bids directly; Cloud Function creates these.
// Includes: fromFirestore/toFirestore

class Bid {
  const Bid({
    required this.id,
    required this.listingId,
    required this.bidderId,
    required this.amount,
    required this.dateCreatedMillis,
  });

  final String id;
  final String listingId;
  final String bidderId;
  final double amount;
  final int dateCreatedMillis;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'listingId': listingId,
      'bidderId': bidderId,
      'amount': amount,
      'dateCreatedMillis': dateCreatedMillis,
    };
  }

  factory Bid.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Bid(
      id: id,
      listingId: _readString(data, 'listingId'),
      bidderId: _readString(data, 'bidderId'),
      amount: _readDouble(data, 'amount'),
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

double _readDouble(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  throw FormatException(
    'Expected "$key" to be a number, got ${value.runtimeType}',
  );
}
