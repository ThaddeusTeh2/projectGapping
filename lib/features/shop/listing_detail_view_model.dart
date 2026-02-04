import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/time.dart';
import '../../di/providers.dart';
import '../../domain/models/shop_listing.dart';
import '../profile/profile_view_model.dart';

// Listing detail ViewModel.
// Responsibilities (SSOT Day 5):
// - Fetch listing
// - Place bid via callable function (BidRepository)
// - Close listing (seller only) and surface permission-denied clearly
// - Buyout listing (buyer) and close immediately

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
  bool _attemptedAutoClose = false;

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

    final listing = result.valueOrNull;
    if (!_attemptedAutoClose && listing != null) {
      final now = nowMillis();
      if (!listing.isClosed && now >= listing.closingTimeMillis) {
        _attemptedAutoClose = true;
        // Fire-and-forget: try to close expired listings to keep UI consistent.
        Future.microtask(() async {
          try {
            await repo.autoCloseExpiredListing(listingId: listing.id);
            await _fetchListing();
          } catch (_) {
            // Best-effort; rules may deny, network may fail.
          }
        });
      }
    }
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
      try {
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

        await ref
            .read(bidRepositoryProvider)
            .placeBid(listingId: listing.id, amount: amount);

        // Refresh detail after a successful bid.
        await _fetchListing();

        // The Profile tab is kept alive in the indexed stack, so it won't
        // necessarily refetch just because a bid was placed elsewhere.
        ref.invalidate(profileViewModelProvider);
      } catch (e, st) {
        debugPrint('placeBid failed: $e');
        debugPrintStack(stackTrace: st);
        rethrow;
      }
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

      await ref
          .read(listingRepositoryProvider)
          .closeListing(
            listingId: listing.id,
            closedAtMillis: nowMillis(),
            closingBid: listing.currentBid,
            winnerUserId: listing.currentBidderId,
          );

      await _fetchListing();

      ref.invalidate(profileViewModelProvider);
    });

    state = state.copyWith(mutation: result);

    return !result.hasError;
  }

  Future<bool> buyoutListing() async {
    state = state.copyWith(mutation: const AsyncLoading());

    final result = await AsyncValue.guard(() async {
      final listing = state.listing.value;
      if (listing == null) throw StateError('Listing not found.');

      final uid = _requireUid();
      if (listing.sellerId == uid) {
        throw StateError("You can't buy out your own listing.");
      }
      if (listing.isClosed) {
        throw StateError('Listing already closed.');
      }
      if (nowMillis() >= listing.closingTimeMillis) {
        // Match bid UX: avoid late buyouts.
        throw StateError('Buyout period has ended.');
      }

      await ref
          .read(listingRepositoryProvider)
          .buyoutListing(
            listingId: listing.id,
            buyerId: uid,
            boughtAtMillis: nowMillis(),
          );

      await _fetchListing();

      ref.invalidate(profileViewModelProvider);
    });

    state = state.copyWith(mutation: result);
    return !result.hasError;
  }
}
