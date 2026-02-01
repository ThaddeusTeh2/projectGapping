import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bike_repository.dart';
import '../../di/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models/bike.dart';

class BikeDirectoryState {
  const BikeDirectoryState({
    required this.brandKey,
    required this.category,
    required this.displacementBucket,
    required this.query,
    required this.sort,
    required this.bikes,
  });

  final String? brandKey;
  final BikeCategory? category;
  final DisplacementBucket? displacementBucket;
  final String query;
  final BikeSort sort;
  final AsyncValue<List<Bike>> bikes;

  BikeDirectoryState copyWith({
    String? brandKey,
    BikeCategory? category,
    DisplacementBucket? displacementBucket,
    String? query,
    BikeSort? sort,
    AsyncValue<List<Bike>>? bikes,
    bool clearBrandKey = false,
    bool clearCategory = false,
    bool clearDisplacementBucket = false,
    bool clearQuery = false,
  }) {
    return BikeDirectoryState(
      brandKey: clearBrandKey ? null : (brandKey ?? this.brandKey),
      category: clearCategory ? null : (category ?? this.category),
      displacementBucket: clearDisplacementBucket
          ? null
          : (displacementBucket ?? this.displacementBucket),
      query: clearQuery ? '' : (query ?? this.query),
      sort: sort ?? this.sort,
      bikes: bikes ?? this.bikes,
    );
  }
}

final bikeDirectoryViewModelProvider =
    NotifierProvider.autoDispose<BikeDirectoryViewModel, BikeDirectoryState>(
      BikeDirectoryViewModel.new,
    );

class BikeDirectoryViewModel extends AutoDisposeNotifier<BikeDirectoryState> {
  List<Bike> _all = const [];
  bool _hasFetched = false;

  @override
  BikeDirectoryState build() {
    final initial = BikeDirectoryState(
      brandKey: null,
      category: null,
      displacementBucket: null,
      query: '',
      sort: BikeSort.titleAsc,
      bikes: const AsyncLoading(),
    );

    state = initial;
    Future.microtask(_fetch);
    return state;
  }

  Future<void> _fetch() async {
    state = state.copyWith(bikes: const AsyncLoading());

    final repo = ref.read(bikeRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      // Firestore strategy: fetch broad, then filter/sort locally.
      // This avoids needing composite indexes for every filter/sort combo.
      final fetched = await repo.listBikes(limit: 500);
      _all = fetched;
      _hasFetched = true;
      return fetched;
    });

    if (result.hasError) {
      state = state.copyWith(bikes: result);
      return;
    }

    _applyFilters();
  }

  void _applyFilters() {
    if (!_hasFetched) return;

    Iterable<Bike> filtered = _all;

    final selectedBrandKey = state.brandKey;
    final selectedCategory = state.category;
    final selectedBucket = state.displacementBucket;
    final query = state.query.trim().toLowerCase();

    if (selectedBrandKey != null) {
      filtered = filtered.where((b) => b.brandKey == selectedBrandKey);
    }
    if (selectedCategory != null) {
      filtered = filtered.where((b) => b.category == selectedCategory.label);
    }
    if (selectedBucket != null) {
      filtered = filtered.where(
        (b) => b.displacementBucket == selectedBucket.key,
      );
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((b) {
        final bucketLabel =
            DisplacementBucket.tryParseKey(b.displacementBucket)?.label ??
            b.displacementBucket;
        return b.titleLower.contains(query) ||
            b.brandLabel.toLowerCase().contains(query) ||
            b.category.toLowerCase().contains(query) ||
            b.displacementBucket.toLowerCase().contains(query) ||
            bucketLabel.toLowerCase().contains(query) ||
            b.releaseYear.toString().contains(query);
      });
    }

    final list = filtered.toList(growable: false);

    // Apply chosen sort locally.
    final sorted = List<Bike>.of(list);
    switch (state.sort) {
      case BikeSort.titleAsc:
        sorted.sort((a, b) => a.titleLower.compareTo(b.titleLower));
      case BikeSort.dateCreatedDesc:
        sorted.sort(
          (a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis),
        );
      case BikeSort.releaseYearDesc:
        sorted.sort((a, b) => b.releaseYear.compareTo(a.releaseYear));
    }

    state = state.copyWith(bikes: AsyncData(sorted));
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

  Future<void> setSort(BikeSort sort) async {
    state = state.copyWith(sort: sort);
    _applyFilters();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
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
