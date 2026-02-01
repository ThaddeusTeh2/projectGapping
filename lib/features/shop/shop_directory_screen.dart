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

class ShopDirectoryScreen extends ConsumerStatefulWidget {
  const ShopDirectoryScreen({super.key});

  @override
  ConsumerState<ShopDirectoryScreen> createState() =>
      _ShopDirectoryScreenState();
}

class _ShopDirectoryScreenState extends ConsumerState<ShopDirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final canClear =
        state.brandKey != null ||
        state.category != null ||
        state.displacementBucket != null ||
        state.query.trim().isNotEmpty;

    return AppScaffold(
      title: 'Shop',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/listing/create'),
        label: const Text('Create Listing'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          ShadInputFormField(
            controller: _searchController,
            label: const Text('Search'),
            placeholder: const Text(
              'Brand, category, cc bucket, title, or release year…',
            ),
            onChanged: viewModel.setQuery,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccordionCard(
              title: 'Filters',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () async {
                        final selected = await pickBrand();
                        await viewModel.setBrandKey(selected);
                      },
                      child: Text(activeBrandLabel),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () async {
                        final selected = await pickCategory();
                        await viewModel.setCategory(selected);
                      },
                      child: Text(activeCategoryLabel),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () async {
                        final selected = await pickBucket();
                        await viewModel.setDisplacementBucket(selected);
                      },
                      child: Text(activeBucketLabel),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: canClear
                          ? () {
                              _searchController.clear();
                              viewModel.clearAll();
                            }
                          : null,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccordionCard(
              title: 'Sort',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: state.sort == ShopSort.newest
                          ? null
                          : () => viewModel.setSort(ShopSort.newest),
                      child: Text(
                        '${state.sort == ShopSort.newest ? '✓ ' : ''}Newest',
                      ),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: state.sort == ShopSort.closingSoon
                          ? null
                          : () => viewModel.setSort(ShopSort.closingSoon),
                      child: Text(
                        '${state.sort == ShopSort.closingSoon ? '✓ ' : ''}Closing soon',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: state.openListings.when(
              data: (openListings) {
                return state.closedListings.when(
                  data: (closedListings) {
                    final openVisible = openListings
                        .take(30)
                        .toList(growable: false);
                    final closedVisible = closedListings
                        .take(30)
                        .toList(growable: false);

                    if (openVisible.isEmpty && closedVisible.isEmpty) {
                      return const EmptyStateView(message: 'No listings yet.');
                    }

                    return ListView(
                      children: [
                        Text(
                          'Open Listings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (openVisible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('No open listings right now.'),
                          )
                        else
                          for (final listing in openVisible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ListingCard(
                                listing: listing,
                                onTap: () =>
                                    context.go('/listing/${listing.id}'),
                              ),
                            ),
                        const SizedBox(height: 8),
                        const Divider(height: 24),
                        Text(
                          'Closed Listings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (closedVisible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('No closed listings yet.'),
                          )
                        else
                          for (final listing in closedVisible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ListingCard(
                                listing: listing,
                                onTap: () =>
                                    context.go('/listing/${listing.id}'),
                              ),
                            ),
                      ],
                    );
                  },
                  error: (error, _) => ErrorStateView(
                    message: 'Failed to load closed listings.',
                    onRetry: viewModel.retry,
                  ),
                  loading: () =>
                      const LoadingView(message: 'Loading closed listings…'),
                );
              },
              error: (error, _) => ErrorStateView(
                message: 'Failed to load open listings.',
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

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
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

    final winnerId = listing.winnerUserId ?? listing.currentBidderId;
    final finalPrice = listing.closingBid ?? listing.currentBid;

    final bidLabel = listing.isClosed
        ? (finalPrice == null
              ? 'Closed'
              : 'Final: ${finalPrice.toStringAsFixed(0)}')
        : (listing.currentBid == null
              ? 'No bids'
              : 'Current: ${listing.currentBid!.toStringAsFixed(0)}');

    return ShadCard(
      child: ListTile(
        title: Text(listing.bikeTitle),
        subtitle: Text(
          '${listing.brandLabel} · ${listing.category} · $bucketLabel\n'
          '$bidLabel · ${listing.isClosed ? 'Status: Closed' : 'Closes in: $closesIn'}'
          '${listing.isClosed && winnerId != null ? '\nWinner: $winnerId' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
