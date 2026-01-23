import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../di/providers.dart';
import '../../domain/models/shop_listing.dart';

// Listing detail ViewModel.
// Responsibilities (SSOT Day 5):
// - Fetch listing
// - Place bid via callable function (BidRepository)
// - Close listing (seller only) and surface permission-denied clearly

class ListingDetailState {
  const ListingDetailState({required this.listing, required this.mutation});

  final AsyncValue<ShopListing?> listing;
  final AsyncValue<void> mutation;

  ListingDetailState copyWith({
    AsyncValue<ShopListing?>? listing,
    AsyncValue<void>? mutation,
  }) {
    return ListingDetailState(
      listing: listing ?? this.listing,
      mutation: mutation ?? this.mutation,
    );
  }
}

final listingDetailViewModelProvider = NotifierProvider.autoDispose
    .family<ListingDetailViewModel, ListingDetailState, String>(
  ListingDetailViewModel.new,
);

class ListingDetailViewModel
    extends AutoDisposeFamilyNotifier<ListingDetailState, String> {
  @override
  ListingDetailState build(String listingId) {
    state = const ListingDetailState(
      listing: AsyncLoading(),
      mutation: AsyncData<void>(null),
    );

    Future.microtask(_fetchListing);
    return state;
  }

  Future<void> _fetchListing() async {
    final repo = ref.read(listingRepositoryProvider);
    final result = await AsyncValue.guard(() => repo.getListingById(arg));
    state = state.copyWith(listing: result);
  }

  Future<void> retry() => _fetchListing();

  String _requireUid() {
    final user = ref.read(authRepositoryProvider).currentUser();
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    return user.uid;
  }

  Future<bool> placeBid({required double amount}) async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final listing = state.listing.value;
      if (listing == null) throw StateError('Listing not found.');

      _requireUid();

      if (listing.isClosed) {
        throw StateError('Listing already closed.');
      }
      if (nowMillis() >= listing.closingTimeMillis) {
        // Even before Day 6 function exists, enforce the UX requirement.
        throw StateError('Bidding has ended.');
      }

      await ref.read(bidRepositoryProvider).placeBid(
            listingId: listing.id,
            amount: amount,
          );

      // Refresh detail after a successful bid.
      await _fetchListing();
    });

    state = state.copyWith(mutation: result);

    return !result.hasError;
  }

  Future<bool> closeListingEarly() async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final listing = state.listing.value;
      if (listing == null) throw StateError('Listing not found.');

      final uid = _requireUid();
      if (listing.sellerId != uid) {
        // SSOT requirement: permission denied feedback.
        throw StateError('You do not own this listing.');
      }

      await ref.read(listingRepositoryProvider).closeListing(
            listingId: listing.id,
            closedAtMillis: nowMillis(),
            closingBid: listing.currentBid,
          );

      await _fetchListing();
    });

    state = state.copyWith(mutation: result);

    return !result.hasError;
  }
}
