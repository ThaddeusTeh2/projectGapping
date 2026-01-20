import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../di/providers.dart';
import '../../domain/models/shop_listing.dart';

final _listingProvider = FutureProvider.autoDispose.family<ShopListing?, String>((ref, listingId) {
	return ref.watch(listingRepositoryProvider).getListingById(listingId);
});

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final listingAsync = ref.watch(_listingProvider(listingId));

    return AppScaffold(
      title: 'Listing Detail',
    body: listingAsync.when(
      data: (listing) {
        if (listing == null) {
          return ErrorStateView(
            message: 'Listing not found.',
            onRetry: () => ref.invalidate(_listingProvider(listingId)),
          );
        }

        final currentBidText = listing.currentBid == null
            ? 'No bids yet'
            : 'Current bid: ${listing.currentBid!.toStringAsFixed(0)}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.bikeTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${listing.brandLabel} · ${listing.category} · ${listing.displacementBucket}'),
            const SizedBox(height: 8),
            Text(currentBidText),
            const SizedBox(height: 12),
            const Text('Placeholder — implement listing info + bid UI on Day 5.'),
          ],
        );
      },
      error: (error, _) => ErrorStateView(
        message: 'Failed to load listing.',
        onRetry: () => ref.invalidate(_listingProvider(listingId)),
      ),
      loading: () => const LoadingView(message: 'Loading listing…'),
    ),
    );
  }
}
