// ShopListing domain model.
// Firestore: listings/{listingId}
// Bid-only listing.
// Fields: bikeId, sellerId, brandKey, brandLabel, category, displacementBucket, bikeTitle,
// hasBid, startingBid, currentBid?, buyOutPrice,
// dateCreatedMillis, closingTimeMillis,
// isClosed, closedAtMillis?, closingBid?, listingComments
// Includes: fromFirestore/toFirestore

class ShopListing {
  const ShopListing({
    required this.id,
    required this.bikeId,
    required this.sellerId,
    required this.brandKey,
    required this.brandLabel,
    required this.category,
    required this.displacementBucket,
    required this.bikeTitle,
    required this.hasBid,
    required this.startingBid,
    required this.currentBid,
    required this.buyOutPrice,
    required this.dateCreatedMillis,
    required this.closingTimeMillis,
    required this.isClosed,
    required this.closedAtMillis,
    required this.closingBid,
    required this.listingComments,
  });

  final String id;
  final String bikeId;
  final String sellerId;
  final String brandKey;
  final String brandLabel;
  final String category;
  final String displacementBucket;
  final String bikeTitle;
  final bool hasBid;
  final double startingBid;
  final double? currentBid;
  final double buyOutPrice;
  final int dateCreatedMillis;
  final int closingTimeMillis;
  final bool isClosed;
  final int? closedAtMillis;
  final double? closingBid;
  final String listingComments;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'bikeId': bikeId,
      'sellerId': sellerId,
      'brandKey': brandKey,
      'brandLabel': brandLabel,
      'category': category,
      'displacementBucket': displacementBucket,
      'bikeTitle': bikeTitle,
      'hasBid': hasBid,
      'startingBid': startingBid,
      'currentBid': currentBid,
      'buyOutPrice': buyOutPrice,
      'dateCreatedMillis': dateCreatedMillis,
      'closingTimeMillis': closingTimeMillis,
      'isClosed': isClosed,
      'closedAtMillis': closedAtMillis,
      'closingBid': closingBid,
      'listingComments': listingComments,
    };
  }

  factory ShopListing.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return ShopListing(
      id: id,
      bikeId: _readString(data, 'bikeId'),
      sellerId: _readString(data, 'sellerId'),
      brandKey: _readString(data, 'brandKey'),
      brandLabel: _readString(data, 'brandLabel'),
      category: _readString(data, 'category'),
      displacementBucket: _readString(data, 'displacementBucket'),
      bikeTitle: _readString(data, 'bikeTitle'),
      hasBid: _readBoolOrDefault(data['hasBid'], defaultValue: false),
      startingBid: _readDouble(data, 'startingBid'),
      currentBid: _readDoubleNullable(data['currentBid']),
      buyOutPrice: _readDouble(data, 'buyOutPrice'),
      dateCreatedMillis: _readInt(data, 'dateCreatedMillis'),
      closingTimeMillis: _readInt(data, 'closingTimeMillis'),
      isClosed: _readBoolOrDefault(data['isClosed'], defaultValue: false),
      closedAtMillis: _readIntNullable(data['closedAtMillis']),
      closingBid: _readDoubleNullable(data['closingBid']),
      listingComments: _readStringOrDefault(
        data['listingComments'],
        defaultValue: '',
      ),
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

String _readStringOrDefault(Object? value, {required String defaultValue}) {
  if (value is String) return value;
  return defaultValue;
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'Expected "$key" to be a number, got ${value.runtimeType}',
  );
}

int? _readIntNullable(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
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
