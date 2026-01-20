// Bike domain model.
// Firestore: motorcycles/{modelId}
// Fields: brandKey, brandLabel, category, displacementBucket, displacementCc,
// title, titleLower, desc, releaseYear, dateCreatedMillis, seaPricingNote, seaFuelNote, seaPartsNote
// Includes: fromFirestore/toFirestore

import '../enums.dart';

class Bike {
  const Bike({
    required this.id,
    required this.brandKey,
    required this.brandLabel,
    required this.category,
    required this.displacementBucket,
    required this.displacementCc,
    required this.title,
    required this.titleLower,
    required this.desc,
    required this.releaseYear,
    required this.dateCreatedMillis,
    required this.seaPricingNote,
    required this.seaFuelNote,
    required this.seaPartsNote,
  });

  final String id;
  final String brandKey;
  final String brandLabel;
  final String category;
  final String displacementBucket;
  final int displacementCc;
  final String title;
  final String titleLower;
  final String desc;
  final int releaseYear;
  final int dateCreatedMillis;
  final String seaPricingNote;
  final String seaFuelNote;
  final String seaPartsNote;

  BikeCategory? get categoryEnum => BikeCategory.tryParseLabel(category);
  DisplacementBucket? get displacementBucketEnum =>
      DisplacementBucket.tryParseKey(displacementBucket);

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'brandKey': brandKey,
      'brandLabel': brandLabel,
      'category': category,
      'displacementBucket': displacementBucket,
      'displacementCc': displacementCc,
      'title': title,
      'titleLower': titleLower,
      'desc': desc,
      'releaseYear': releaseYear,
      'dateCreatedMillis': dateCreatedMillis,
      'seaPricingNote': seaPricingNote,
      'seaFuelNote': seaFuelNote,
      'seaPartsNote': seaPartsNote,
    };
  }

  factory Bike.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Bike(
      id: id,
      brandKey: _readString(data, 'brandKey'),
      brandLabel: _readString(data, 'brandLabel'),
      category: _readString(data, 'category'),
      displacementBucket: _readString(data, 'displacementBucket'),
      displacementCc: _readInt(data, 'displacementCc'),
      title: _readString(data, 'title'),
      titleLower: _readString(data, 'titleLower'),
      desc: _readString(data, 'desc'),
      releaseYear: _readInt(data, 'releaseYear'),
      dateCreatedMillis: _readInt(data, 'dateCreatedMillis'),
      seaPricingNote: _readString(data, 'seaPricingNote'),
      seaFuelNote: _readString(data, 'seaFuelNote'),
      seaPartsNote: _readString(data, 'seaPartsNote'),
    );
  }

  Bike copyWith({
    String? id,
    String? brandKey,
    String? brandLabel,
    String? category,
    String? displacementBucket,
    int? displacementCc,
    String? title,
    String? titleLower,
    String? desc,
    int? releaseYear,
    int? dateCreatedMillis,
    String? seaPricingNote,
    String? seaFuelNote,
    String? seaPartsNote,
  }) {
    return Bike(
      id: id ?? this.id,
      brandKey: brandKey ?? this.brandKey,
      brandLabel: brandLabel ?? this.brandLabel,
      category: category ?? this.category,
      displacementBucket: displacementBucket ?? this.displacementBucket,
      displacementCc: displacementCc ?? this.displacementCc,
      title: title ?? this.title,
      titleLower: titleLower ?? this.titleLower,
      desc: desc ?? this.desc,
      releaseYear: releaseYear ?? this.releaseYear,
      dateCreatedMillis: dateCreatedMillis ?? this.dateCreatedMillis,
      seaPricingNote: seaPricingNote ?? this.seaPricingNote,
      seaFuelNote: seaFuelNote ?? this.seaFuelNote,
      seaPartsNote: seaPartsNote ?? this.seaPartsNote,
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
