import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final viewModel = ref.read(listingDetailViewModelProvider(listingId).notifier);

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

          final isOwner = currentUser?.uid != null && currentUser!.uid == listing.sellerId;
          final now = nowMillis();
          final biddingOpen = !listing.isClosed && now < listing.closingTimeMillis;
          final closesAt = DateTime.fromMillisecondsSinceEpoch(listing.closingTimeMillis);
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
              _kv('Status', listing.isClosed ? 'CLOSED' : 'OPEN'),
              _kv('Starting', listing.startingBid.toStringAsFixed(0)),
              _kv(
                'Current',
                listing.currentBid == null
                    ? 'No bids yet'
                    : listing.currentBid!.toStringAsFixed(0),
              ),
              _kv('Buyout', listing.buyOutPrice.toStringAsFixed(0)),
              _kv('Closes in', closesIn),
              _kv('Closes at', closesAt.toLocal().toString()),
              const SizedBox(height: 16),
              Text(
                'Seller Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(listing.listingComments.isEmpty ? '(none)' : listing.listingComments),
              const SizedBox(height: 20),
              _BidSection(
                listingId: listing.id,
                currentBid: listing.currentBid,
                startingBid: listing.startingBid,
                enabled: biddingOpen && !state.mutation.isLoading,
              ),
              const SizedBox(height: 20),
              Text(
                'Seller Controls',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.mutation.isLoading
                      ? null
                      : () async {
                          if (!isOwner) {
                            // SSOT: permission-denied feedback for non-owner.
                            AppSnackbar.showError(context, 'You do not own this listing.');
                            return;
                          }
                          final ok = await viewModel.closeListingEarly();
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackbar.showSuccess(context, 'Listing closed');
                          }
                        },
                  icon: const Icon(Icons.lock_outline),
                  label: Text(isOwner ? 'Close Listing Early' : 'Close Listing (Owner only)'),
                ),
              ),
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
        Text(
          'Place Bid',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (MYR)'),
                validator: (v) => Validators.bidAmount(
                  value: v,
                  currentBid: widget.currentBid,
                  startingBid: widget.startingBid,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.enabled
                      ? () async {
                          final valid = _formKey.currentState?.validate() ?? false;
                          if (!valid) return;
                          final amount = double.parse(_amountController.text.trim());
                          final ok = await ref
                              .read(
                                listingDetailViewModelProvider(widget.listingId)
                                    .notifier,
                              )
                              .placeBid(amount: amount);
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackbar.showSuccess(context, 'Bid placed');
                          }
                        }
                      : null,
                  child: Text(widget.enabled ? 'Place Bid' : 'Bidding unavailable'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text('$k:')),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
