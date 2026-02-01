import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
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
    required this.query,
    required this.sort,
    required this.openListings,
    required this.closedListings,
  });

  final String? brandKey;
  final BikeCategory? category;
  final DisplacementBucket? displacementBucket;
  final String query;
  final ShopSort sort;
  final AsyncValue<List<ShopListing>> openListings;
  final AsyncValue<List<ShopListing>> closedListings;

  ShopDirectoryState copyWith({
    String? brandKey,
    BikeCategory? category,
    DisplacementBucket? displacementBucket,
    String? query,
    ShopSort? sort,
    AsyncValue<List<ShopListing>>? openListings,
    AsyncValue<List<ShopListing>>? closedListings,
    bool clearBrandKey = false,
    bool clearCategory = false,
    bool clearDisplacementBucket = false,
    bool clearQuery = false,
  }) {
    return ShopDirectoryState(
      brandKey: clearBrandKey ? null : (brandKey ?? this.brandKey),
      category: clearCategory ? null : (category ?? this.category),
      displacementBucket: clearDisplacementBucket
          ? null
          : (displacementBucket ?? this.displacementBucket),
      query: clearQuery ? '' : (query ?? this.query),
      sort: sort ?? this.sort,
      openListings: openListings ?? this.openListings,
      closedListings: closedListings ?? this.closedListings,
    );
  }
}

enum ShopSort { newest, closingSoon }

final shopDirectoryViewModelProvider =
    NotifierProvider.autoDispose<ShopDirectoryViewModel, ShopDirectoryState>(
      ShopDirectoryViewModel.new,
    );

class ShopDirectoryViewModel extends AutoDisposeNotifier<ShopDirectoryState> {
  List<ShopListing> _openAll = const [];
  List<ShopListing> _closedAll = const [];
  bool _hasFetched = false;

  @override
  ShopDirectoryState build() {
    state = const ShopDirectoryState(
      brandKey: null,
      category: null,
      displacementBucket: null,
      query: '',
      sort: ShopSort.newest,
      openListings: AsyncLoading(),
      closedListings: AsyncLoading(),
    );

    Future.microtask(_fetch);
    return state;
  }

  Future<void> _fetch() async {
    state = state.copyWith(
      openListings: const AsyncLoading(),
      closedListings: const AsyncLoading(),
    );

    final repo = ref.read(listingRepositoryProvider);

    final openResult = await AsyncValue.guard(() async {
      final fetched = await repo.listListings(isClosed: false, limit: 500);
      _openAll = fetched;
      return fetched;
    });

    final closedResult = await AsyncValue.guard(() async {
      final fetched = await repo.listListings(isClosed: true, limit: 500);
      _closedAll = fetched;
      return fetched;
    });

    if (openResult.hasError) {
      state = state.copyWith(openListings: openResult);
      return;
    }
    if (closedResult.hasError) {
      state = state.copyWith(closedListings: closedResult);
      return;
    }

    _hasFetched = true;
    _applyFilters();
  }

  void _applyFilters() {
    if (!_hasFetched) return;

    final selectedBrandKey = state.brandKey;
    final selectedCategory = state.category;
    final selectedBucket = state.displacementBucket;
    final query = state.query.trim().toLowerCase();
    final now = nowMillis();

    bool matchesQuery(ShopListing l) {
      if (query.isEmpty) return true;
      final bucketLabel =
          DisplacementBucket.tryParseKey(l.displacementBucket)?.label ??
          l.displacementBucket;
      return l.bikeTitle.toLowerCase().contains(query) ||
          l.brandLabel.toLowerCase().contains(query) ||
          l.category.toLowerCase().contains(query) ||
          l.displacementBucket.toLowerCase().contains(query) ||
          bucketLabel.toLowerCase().contains(query) ||
          (l.bikeReleaseYear?.toString().contains(query) ?? false);
    }

    Iterable<ShopListing> openFiltered = _openAll;
    openFiltered = openFiltered.where((l) => now < l.closingTimeMillis);

    if (selectedBrandKey != null) {
      openFiltered = openFiltered.where((l) => l.brandKey == selectedBrandKey);
    }
    if (selectedCategory != null) {
      openFiltered = openFiltered.where(
        (l) => l.category == selectedCategory.label,
      );
    }
    if (selectedBucket != null) {
      openFiltered = openFiltered.where(
        (l) => l.displacementBucket == selectedBucket.key,
      );
    }
    openFiltered = openFiltered.where(matchesQuery);

    final openList = openFiltered.toList(growable: false);
    final openSorted = List<ShopListing>.of(openList);
    switch (state.sort) {
      case ShopSort.newest:
        openSorted.sort(
          (a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis),
        );
      case ShopSort.closingSoon:
        openSorted.sort(
          (a, b) => a.closingTimeMillis.compareTo(b.closingTimeMillis),
        );
    }

    Iterable<ShopListing> closedFiltered = _closedAll;
    if (selectedBrandKey != null) {
      closedFiltered = closedFiltered.where(
        (l) => l.brandKey == selectedBrandKey,
      );
    }
    if (selectedCategory != null) {
      closedFiltered = closedFiltered.where(
        (l) => l.category == selectedCategory.label,
      );
    }
    if (selectedBucket != null) {
      closedFiltered = closedFiltered.where(
        (l) => l.displacementBucket == selectedBucket.key,
      );
    }
    closedFiltered = closedFiltered.where(matchesQuery);

    final closedList = closedFiltered.toList(growable: false);
    final closedSorted = List<ShopListing>.of(closedList)
      ..sort((a, b) {
        final aClosed = a.closedAtMillis ?? a.dateCreatedMillis;
        final bClosed = b.closedAtMillis ?? b.dateCreatedMillis;
        return bClosed.compareTo(aClosed);
      });

    state = state.copyWith(
      openListings: AsyncData(openSorted),
      closedListings: AsyncData(closedSorted),
    );
  }

  Future<void> retry() => _fetch();

  Future<void> setBrandKey(String? brandKey) async {
    state = state.copyWith(brandKey: brandKey);
    _applyFilters();
  }

  Future<void> setCategory(BikeCategory? category) async {
    state = state.copyWith(category: category);
    _applyFilters();
  }

  Future<void> setDisplacementBucket(DisplacementBucket? bucket) async {
    state = state.copyWith(displacementBucket: bucket);
    _applyFilters();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _applyFilters();
  }

  void setSort(ShopSort sort) {
    state = state.copyWith(sort: sort);
    _applyFilters();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearBrandKey: true,
      clearCategory: true,
      clearDisplacementBucket: true,
    );
    _applyFilters();
  }

  void clearAll() {
    state = state.copyWith(
      clearBrandKey: true,
      clearCategory: true,
      clearDisplacementBucket: true,
      clearQuery: true,
    );
    _applyFilters();
  }
}
