import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../core/utils/time.dart';
import '../../domain/enums.dart';
import '../../domain/models/shop_listing.dart';
import 'shop_directory_view_model.dart';

class ShopDirectoryScreen extends ConsumerWidget {
  const ShopDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SSOT Day 5: filter UI + listing cards + empty/error states.
    // Firestore strategy: fetch broad slice and filter/sort locally (demo-scale).
    final state = ref.watch(shopDirectoryViewModelProvider);
    final viewModel = ref.read(shopDirectoryViewModelProvider.notifier);

    Future<String?> pickBrand() {
      return showDialog<String?>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Brand'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Any'),
              ),
              for (final b in CanonicalBrands.all)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, b.key),
                  child: Text(b.label),
                ),
            ],
          );
        },
      );
    }

    Future<BikeCategory?> pickCategory() {
      return showDialog<BikeCategory?>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Category'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Any'),
              ),
              for (final c in BikeCategory.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, c),
                  child: Text(c.label),
                ),
            ],
          );
        },
      );
    }

    Future<DisplacementBucket?> pickBucket() {
      return showDialog<DisplacementBucket?>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Displacement'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Any'),
              ),
              for (final b in DisplacementBucket.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, b),
                  child: Text(b.label),
                ),
            ],
          );
        },
      );
    }

    final activeBrandLabel =
        CanonicalBrands.labelForKey(state.brandKey) ?? 'Any brand';
    final activeCategoryLabel = state.category?.label ?? 'Any category';
    final activeBucketLabel = state.displacementBucket?.label ?? 'Any cc';

    return AppScaffold(
      title: 'Shop',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/listing/create'),
        label: const Text('Create Listing'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  label: Text(activeBrandLabel),
                  onPressed: () async {
                    final selected = await pickBrand();
                    await viewModel.setBrandKey(selected);
                  },
                ),
                ActionChip(
                  label: Text(activeCategoryLabel),
                  onPressed: () async {
                    final selected = await pickCategory();
                    await viewModel.setCategory(selected);
                  },
                ),
                ActionChip(
                  label: Text(activeBucketLabel),
                  onPressed: () async {
                    final selected = await pickBucket();
                    await viewModel.setDisplacementBucket(selected);
                  },
                ),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed:
                      (state.brandKey != null ||
                              state.category != null ||
                              state.displacementBucket != null)
                          ? viewModel.clearFilters
                          : null,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Note: to avoid Firestore composite-index combinatorics, the app fetches a broad set and filters/sorts locally for demo-scale data.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: state.listings.when(
              data: (listings) {
                final visible = listings.take(30).toList(growable: false);
                if (visible.isEmpty) {
                  return const EmptyStateView(message: 'No listings yet.');
                }

                return ListView(
                  children: [
                    for (final listing in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ListingCard(
                          listing: listing,
                          onTap: () => context.go('/listing/${listing.id}'),
                        ),
                      ),
                  ],
                );
              },
              error: (error, _) => ErrorStateView(
                message: 'Failed to load listings.',
                onRetry: viewModel.retry,
              ),
              loading: () => const LoadingView(message: 'Loading listings…'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final ShopListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = nowMillis();
    final remaining = Duration(
      milliseconds: (listing.closingTimeMillis - now).clamp(0, 1 << 62),
    );
    final closesIn = listing.isClosed
        ? 'Closed'
        : remaining.inMinutes < 60
            ? '${remaining.inMinutes}m'
            : remaining.inHours < 24
                ? '${remaining.inHours}h'
                : '${remaining.inDays}d';

    final bucketLabel =
        DisplacementBucket.tryParseKey(listing.displacementBucket)?.label ??
            listing.displacementBucket;
    final bidLabel = listing.currentBid == null
        ? 'No bids'
        : 'Current: ${listing.currentBid!.toStringAsFixed(0)}';

    return ShadCard(
      child: ListTile(
        title: Text(listing.bikeTitle),
        subtitle: Text('${listing.brandLabel} · ${listing.category} · $bucketLabel\n$bidLabel · Closes in: $closesIn'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
