import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../core/utils/time.dart';
import '../../core/validation/validators.dart';
import '../../di/providers.dart';
import 'listing_detail_view_model.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String userMessageFromError(Object error) {
      // AsyncValue.guard commonly wraps StateError as "Bad state: ...".
      final raw = error.toString();
      const badStatePrefix = 'Bad state: ';
      if (raw.startsWith(badStatePrefix)) {
        return raw.substring(badStatePrefix.length);
      }
      return raw;
    }

    // SSOT Day 5: listing info + bid form + seller controls.
    final state = ref.watch(listingDetailViewModelProvider(listingId));
    final viewModel = ref.read(
      listingDetailViewModelProvider(listingId).notifier,
    );

    final currentUser = ref.watch(authRepositoryProvider).currentUser();

    ref.listen(
      listingDetailViewModelProvider(listingId).select((s) => s.mutation),
      (previous, next) {
        if (next.hasError && !next.isLoading) {
          AppSnackbar.showError(context, userMessageFromError(next.error!));
        }
      },
    );

    return AppScaffold(
      title: 'Listing Detail',
      body: state.listing.when(
        data: (listing) {
          if (listing == null) {
            return ErrorStateView(
              message: 'Listing not found.',
              onRetry: viewModel.retry,
            );
          }

          final isOwner =
              currentUser?.uid != null && currentUser!.uid == listing.sellerId;
          final now = nowMillis();
          final biddingOpen =
              !listing.isClosed && now < listing.closingTimeMillis;
          final canBuyout = !isOwner && biddingOpen;
          final winnerId = listing.winnerUserId ?? listing.currentBidderId;
          final finalPrice = listing.closingBid ?? listing.currentBid;
          final closesAt = DateTime.fromMillisecondsSinceEpoch(
            listing.closingTimeMillis,
          );
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

          return ListView(
            children: [
              Text(
                listing.bikeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${listing.brandLabel} · ${listing.category} · ${listing.displacementBucket}',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'People',
                separated: true,
                children: [
                  _kv(context, 'Seller', listing.sellerId),
                  if (!listing.isClosed && listing.currentBidderId != null)
                    _kv(context, 'Leader', listing.currentBidderId!),
                  if (listing.isClosed && winnerId != null)
                    _kv(context, 'Winner', winnerId),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Pricing',
                separated: true,
                children: [
                  _kv(
                    context,
                    'Starting',
                    listing.startingBid.toStringAsFixed(0),
                  ),
                  _kv(
                    context,
                    listing.isClosed ? 'Final' : 'Current',
                    listing.currentBid == null
                        ? 'No bids yet'
                        : (listing.isClosed && finalPrice != null
                              ? finalPrice.toStringAsFixed(0)
                              : listing.currentBid!.toStringAsFixed(0)),
                  ),
                  _kv(
                    context,
                    'Buyout',
                    listing.buyOutPrice.toStringAsFixed(0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Timing',
                separated: true,
                children: [
                  _kv(context, 'Status', listing.isClosed ? 'CLOSED' : 'OPEN'),
                  _kv(context, 'Closes in', closesIn),
                  _kv(context, 'Closes at', closesAt.toLocal().toString()),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Seller Notes',
                children: [
                  Text(
                    listing.listingComments.isEmpty
                        ? '(none)'
                        : listing.listingComments,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (canBuyout)
                _SectionCard(
                  title: 'Buyout',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(
                        onPressed: state.mutation.isLoading
                            ? null
                            : () async {
                                if (currentUser?.uid == null) {
                                  AppSnackbar.showError(
                                    context,
                                    'You must be signed in to buy out.',
                                  );
                                  return;
                                }
                                final ok = await viewModel.buyoutListing();
                                if (!context.mounted) return;
                                if (ok) {
                                  AppSnackbar.showSuccess(
                                    context,
                                    'Listing bought out',
                                  );
                                }
                              },
                        leading: const Icon(Icons.shopping_cart_checkout),
                        child: Text(
                          'Buyout for ${listing.buyOutPrice.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Bid',
                children: [
                  _BidSection(
                    listingId: listing.id,
                    currentBid: listing.currentBid,
                    startingBid: listing.startingBid,
                    enabled: biddingOpen && !state.mutation.isLoading,
                  ),
                ],
              ),
              if (isOwner) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Seller Controls',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(
                        onPressed: state.mutation.isLoading
                            ? null
                            : () async {
                                final ok = await viewModel.closeListingEarly();
                                if (!context.mounted) return;
                                if (ok) {
                                  AppSnackbar.showSuccess(
                                    context,
                                    'Listing closed',
                                  );
                                }
                              },
                        leading: const Icon(Icons.lock_outline),
                        child: const Text('Close Listing Early'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          );
        },
        error: (error, _) => ErrorStateView(
          message: 'Failed to load listing.',
          onRetry: viewModel.retry,
        ),
        loading: () => const LoadingView(message: 'Loading listing…'),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.separated = false,
  });

  final String title;
  final List<Widget> children;
  final bool separated;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!separated) ...children,
            if (separated)
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const ShadSeparator.horizontal(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    thickness: 1,
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _BidSection extends ConsumerStatefulWidget {
  const _BidSection({
    required this.listingId,
    required this.currentBid,
    required this.startingBid,
    required this.enabled,
  });

  final String listingId;
  final double? currentBid;
  final double startingBid;
  final bool enabled;

  @override
  ConsumerState<_BidSection> createState() => _BidSectionState();
}

class _BidSectionState extends ConsumerState<_BidSection> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SSOT Day 5: client validates first, then calls callable function.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Place Bid', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              ShadInputFormField(
                controller: _amountController,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: const Text('Amount (MYR)'),
                validator: (v) => Validators.bidAmount(
                  value: v,
                  currentBid: widget.currentBid,
                  startingBid: widget.startingBid,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: widget.enabled
                      ? () async {
                          final valid =
                              _formKey.currentState?.validate() ?? false;
                          if (!valid) return;
                          final amount = double.parse(
                            _amountController.text.trim(),
                          );
                          final ok = await ref
                              .read(
                                listingDetailViewModelProvider(
                                  widget.listingId,
                                ).notifier,
                              )
                              .placeBid(amount: amount);
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackbar.showSuccess(context, 'Bid placed');
                          }
                        }
                      : null,
                  child: Text(
                    widget.enabled ? 'Place Bid' : 'Bidding unavailable',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _kv(BuildContext context, String label, String value) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: theme.textTheme.labelMedium),
      const SizedBox(height: 2),
      Text(value),
    ],
  );
}
