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
    required this.sort,
    required this.bikes,
  });

  final String? brandKey;
  final BikeCategory? category;
  final DisplacementBucket? displacementBucket;
  final BikeSort sort;
  final AsyncValue<List<Bike>> bikes;

  BikeDirectoryState copyWith({
    String? brandKey,
    BikeCategory? category,
    DisplacementBucket? displacementBucket,
    BikeSort? sort,
    AsyncValue<List<Bike>>? bikes,
    bool clearBrandKey = false,
    bool clearCategory = false,
    bool clearDisplacementBucket = false,
  }) {
    return BikeDirectoryState(
      brandKey: clearBrandKey ? null : (brandKey ?? this.brandKey),
      category: clearCategory ? null : (category ?? this.category),
      displacementBucket: clearDisplacementBucket
          ? null
          : (displacementBucket ?? this.displacementBucket),
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
  @override
  BikeDirectoryState build() {
    final initial = BikeDirectoryState(
      brandKey: null,
      category: null,
      displacementBucket: null,
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

      Iterable<Bike> filtered = fetched;

      final selectedBrandKey = state.brandKey;
      final selectedCategory = state.category;
      final selectedBucket = state.displacementBucket;

      if (selectedBrandKey != null) {
        filtered = filtered.where((b) => b.brandKey == selectedBrandKey);
      }
      if (selectedCategory != null) {
        filtered = filtered.where((b) => b.category == selectedCategory.label);
      }
      if (selectedBucket != null) {
        filtered = filtered.where((b) => b.displacementBucket == selectedBucket.key);
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

      return sorted;
    });

    state = state.copyWith(bikes: result);
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

  Future<void> setSort(BikeSort sort) async {
    state = state.copyWith(sort: sort);
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
