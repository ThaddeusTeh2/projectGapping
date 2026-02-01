import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../di/providers.dart';
import '../../domain/models/bike.dart';
import '../../domain/models/shop_listing.dart';

// Create listing ViewModel.
// Responsibilities (SSOT Day 5):
// - Load bike models for selection
// - Publish listing document with required denormalized fields
// - Keep Firebase SDK usage out of UI

class CreateListingState {
  const CreateListingState({
    required this.query,
    required this.bikes,
    required this.selectedBike,
    required this.mutation,
  });

  final String query;
  final AsyncValue<List<Bike>> bikes;
  final Bike? selectedBike;
  final AsyncValue<String?> mutation; // returns created listingId

  CreateListingState copyWith({
    String? query,
    AsyncValue<List<Bike>>? bikes,
    Bike? selectedBike,
    bool clearSelectedBike = false,
    AsyncValue<String?>? mutation,
  }) {
    return CreateListingState(
      query: query ?? this.query,
      bikes: bikes ?? this.bikes,
      selectedBike: clearSelectedBike
          ? null
          : (selectedBike ?? this.selectedBike),
      mutation: mutation ?? this.mutation,
    );
  }
}

final createListingViewModelProvider =
    NotifierProvider.autoDispose<CreateListingViewModel, CreateListingState>(
      CreateListingViewModel.new,
    );

class CreateListingViewModel extends AutoDisposeNotifier<CreateListingState> {
  @override
  CreateListingState build() {
    state = const CreateListingState(
      query: '',
      bikes: AsyncLoading(),
      selectedBike: null,
      mutation: AsyncData<String?>(null),
    );

    Future.microtask(_fetchBikes);
    return state;
  }

  Future<void> _fetchBikes() async {
    state = state.copyWith(bikes: const AsyncLoading());

    final repo = ref.read(bikeRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      // Broad fetch; search/filter happens in UI for now.
      return repo.listBikes(limit: 500);
    });

    state = state.copyWith(bikes: result);
  }

  Future<void> retry() => _fetchBikes();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void selectBike(Bike bike) {
    state = state.copyWith(selectedBike: bike);
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedBike: true);
  }

  String _requireUid() {
    final user = ref.read(authRepositoryProvider).currentUser();
    if (user == null) throw StateError('You must be signed in.');
    return user.uid;
  }

  Future<String?> publishListing({
    required double startingBid,
    required double buyOutPrice,
    required ListingDurationPreset preset,
    required String listingComments,
  }) async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final bike = state.selectedBike;
      if (bike == null) throw StateError('Select a bike model first.');

      final sellerId = _requireUid();
      final createdMillis = nowMillis();

      // Denormalization required by SSOT for fast filtering.
      final listing = ShopListing(
        id: '_new',
        bikeId: bike.id,
        sellerId: sellerId,
        brandKey: bike.brandKey,
        brandLabel: bike.brandLabel,
        category: bike.category,
        displacementBucket: bike.displacementBucket,
        bikeTitle: bike.title,
        bikeReleaseYear: bike.releaseYear,
        hasBid: false,
        startingBid: startingBid,
        currentBid: null,
        buyOutPrice: buyOutPrice,
        dateCreatedMillis: createdMillis,
        closingTimeMillis: closingTimeMillisFromPreset(
          preset,
          fromMillis: createdMillis,
        ),
        isClosed: false,
        closedAtMillis: null,
        closingBid: null,
        listingComments: listingComments.trim(),
      );

      final listingId = await ref
          .read(listingRepositoryProvider)
          .createListing(listing);
      return listingId;
    });

    state = state.copyWith(mutation: result);
    return result.valueOrNull;
  }
}
