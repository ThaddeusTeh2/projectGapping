// Time helpers.
// Responsibilities:
// - nowMillis()
// - preset duration -> closingTimeMillis helpers (1h/6h/24h/3d)

enum ListingDurationPreset {
	h1(Duration(hours: 1), '1h'),
	h6(Duration(hours: 6), '6h'),
	h24(Duration(hours: 24), '24h'),
	d3(Duration(days: 3), '3d');

	const ListingDurationPreset(this.duration, this.label);
	final Duration duration;
	final String label;
}

int nowMillis() => DateTime.now().millisecondsSinceEpoch;

int closingTimeMillisFromPreset(ListingDurationPreset preset, {int? fromMillis}) {
	final base = DateTime.fromMillisecondsSinceEpoch(fromMillis ?? nowMillis());
	return base.add(preset.duration).millisecondsSinceEpoch;
}
