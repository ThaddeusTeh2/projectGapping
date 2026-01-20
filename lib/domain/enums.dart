// Domain enums + canonical mappings.
// Responsibilities:
// - bikeCategory values (Sport/Naked/Scooter/Adventure/Cruiser/Offroad)
// - displacementBucket values + labels
// - brandKey <-> brandLabel mapping

enum BikeCategory {
	sport('Sport'),
	naked('Naked'),
	scooter('Scooter'),
	adventure('Adventure'),
	cruiser('Cruiser'),
	offroad('Offroad');

	const BikeCategory(this.label);
	final String label;

	static BikeCategory? tryParseLabel(String? value) {
		if (value == null) return null;
		for (final item in BikeCategory.values) {
			if (item.label.toLowerCase() == value.toLowerCase()) return item;
		}
		return null;
	}
}

enum DisplacementBucket {
	cc0to150('0_150', '0–150cc'),
	cc151to250('151_250', '151–250cc'),
	cc251to400('251_400', '251–400cc'),
	cc401to650('401_650', '401–650cc'),
	cc651Plus('651_plus', '651cc+');

	const DisplacementBucket(this.key, this.label);
	final String key;
	final String label;

	static DisplacementBucket? tryParseKey(String? value) {
		if (value == null) return null;
		for (final item in DisplacementBucket.values) {
			if (item.key.toLowerCase() == value.toLowerCase()) return item;
		}
		return null;
	}
}

class Brand {
	const Brand({required this.key, required this.label});

	final String key;
	final String label;
}

class CanonicalBrands {
	CanonicalBrands._();

	static const List<Brand> all = <Brand>[
		Brand(key: 'kawasaki', label: 'Kawasaki'),
		Brand(key: 'honda', label: 'Honda'),
		Brand(key: 'yamaha', label: 'Yamaha'),
		Brand(key: 'suzuki', label: 'Suzuki'),
		Brand(key: 'bmw', label: 'BMW'),
		Brand(key: 'aprilia', label: 'Aprilia'),
		Brand(key: 'cfmoto', label: 'CFMOTO'),
		Brand(key: 'ducati', label: 'Ducati'),
		Brand(key: 'harley_davidson', label: 'Harley Davidson'),
		Brand(key: 'ktm', label: 'KTM'),
		Brand(key: 'triumph', label: 'Triumph'),
		Brand(key: 'vespa', label: 'Vespa'),
	];

	static String? labelForKey(String? brandKey) {
		if (brandKey == null) return null;
		for (final brand in all) {
			if (brand.key.toLowerCase() == brandKey.toLowerCase()) return brand.label;
		}
		return null;
	}

	static String? keyForLabel(String? brandLabel) {
		if (brandLabel == null) return null;
		for (final brand in all) {
			if (brand.label.toLowerCase() == brandLabel.toLowerCase()) return brand.key;
		}
		return null;
	}
}
