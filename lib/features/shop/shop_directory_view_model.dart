import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models/shop_listing.dart';

// Shop directory ViewModel.
// Responsibilities (SSOT Day 5):
// - Fetch listings (broad slice) and apply filter/sort locally (demo-scale approach)
// - Expose loading/data/error state and mutation-free filtering actions
// - Keep Firestore SDK usage out of UI

class ShopDirectoryState {
  const ShopDirectoryState({
    required this.brandKey,
    required this.category,
    required this.displacementBucket,
    required this.listings,
  });

  final String? brandKey;
  final BikeCategory? category;
  final DisplacementBucket? displacementBucket;
  final AsyncValue<List<ShopListing>> listings;

  ShopDirectoryState copyWith({
    String? brandKey,
    BikeCategory? category,
    DisplacementBucket? displacementBucket,
    AsyncValue<List<ShopListing>>? listings,
    bool clearBrandKey = false,
    bool clearCategory = false,
    bool clearDisplacementBucket = false,
  }) {
    return ShopDirectoryState(
      brandKey: clearBrandKey ? null : (brandKey ?? this.brandKey),
      category: clearCategory ? null : (category ?? this.category),
      displacementBucket: clearDisplacementBucket
          ? null
          : (displacementBucket ?? this.displacementBucket),
      listings: listings ?? this.listings,
    );
  }
}

final shopDirectoryViewModelProvider =
    NotifierProvider.autoDispose<ShopDirectoryViewModel, ShopDirectoryState>(
  ShopDirectoryViewModel.new,
);

class ShopDirectoryViewModel extends AutoDisposeNotifier<ShopDirectoryState> {
  @override
  ShopDirectoryState build() {
    state = const ShopDirectoryState(
      brandKey: null,
      category: null,
      displacementBucket: null,
      listings: AsyncLoading(),
    );

    Future.microtask(_fetch);
    return state;
  }

  Future<void> _fetch() async {
    state = state.copyWith(listings: const AsyncLoading());

    final repo = ref.read(listingRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      // Firestore strategy (SSOT footnote): fetch broad, then filter/sort locally.
      final fetched = await repo.listListings(limit: 500);

      Iterable<ShopListing> filtered = fetched;

      // Default behavior from SSOT: show open listings by default.
      filtered = filtered.where((l) => !l.isClosed);

      final selectedBrandKey = state.brandKey;
      final selectedCategory = state.category;
      final selectedBucket = state.displacementBucket;

      if (selectedBrandKey != null) {
        filtered = filtered.where((l) => l.brandKey == selectedBrandKey);
      }
      if (selectedCategory != null) {
        filtered = filtered.where((l) => l.category == selectedCategory.label);
      }
      if (selectedBucket != null) {
        filtered = filtered.where(
          (l) => l.displacementBucket == selectedBucket.key,
        );
      }

      final list = filtered.toList(growable: false);

      final sorted = List<ShopListing>.of(list)
        ..sort((a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis));

      return sorted;
    });

    state = state.copyWith(listings: result);
  }

  Future<void> retry() => _fetch();

  Future<void> setBrandKey(String? brandKey) async {
    state = state.copyWith(brandKey: brandKey);
    await _fetch();
  }

  Future<void> setCategory(BikeCategory? category) async {
    state = state.copyWith(category: category);
    await _fetch();
  }

  Future<void> setDisplacementBucket(DisplacementBucket? bucket) async {
    state = state.copyWith(displacementBucket: bucket);
    await _fetch();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearBrandKey: true,
      clearCategory: true,
      clearDisplacementBucket: true,
    );
    await _fetch();
  }
}
