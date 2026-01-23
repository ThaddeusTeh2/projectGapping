import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../core/utils/time.dart';
import '../../core/validation/validators.dart';
import '../../domain/models/bike.dart';
import 'create_listing_view_model.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _startingBidController = TextEditingController();
  final _buyoutController = TextEditingController();
  final _notesController = TextEditingController();

  ListingDurationPreset? _preset;

  @override
  void dispose() {
    _searchController.dispose();
    _startingBidController.dispose();
    _buyoutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SSOT Day 5: select bike + form fields + duration presets.
    // Denormalization requirement: listing must write brandKey/brandLabel/category/displacementBucket/bikeTitle.
    final state = ref.watch(createListingViewModelProvider);
    final viewModel = ref.read(createListingViewModelProvider.notifier);

    ref.listen(
      createListingViewModelProvider.select((s) => s.mutation),
      (previous, next) {
        if (next.hasError && !next.isLoading) {
          AppSnackbar.showError(context, next.error.toString());
        }
      },
    );

    final isSubmitting = state.mutation.isLoading;
    final startingBid = double.tryParse(_startingBidController.text.trim());

    return AppScaffold(
      title: 'Create Listing',
      actions: [
        IconButton(
          tooltip: 'Reload bikes',
          onPressed: isSubmitting ? null : viewModel.retry,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        children: [
          Text(
            'Select Bike Model',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Type a model name…',
            ),
            onChanged: viewModel.setQuery,
          ),
          const SizedBox(height: 12),
          _SelectedBikeCard(
            bike: state.selectedBike,
            onClear: isSubmitting ? null : viewModel.clearSelection,
          ),
          const SizedBox(height: 12),
          state.bikes.when(
            data: (bikes) {
              final query = state.query.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? bikes
                  : bikes
                      .where(
                        (b) =>
                            b.titleLower.contains(query) ||
                            b.brandLabel.toLowerCase().contains(query),
                      )
                      .toList(growable: false);

              final visible = filtered.take(25).toList(growable: false);

              if (visible.isEmpty) {
                return const EmptyStateView(message: 'No bikes match your search.');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick from bikes list',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final bike in visible)
                    Card(
                      child: ListTile(
                        title: Text(bike.title),
                        subtitle: Text('${bike.brandLabel} · ${bike.category} · ${bike.displacementBucket}'),
                        trailing: state.selectedBike?.id == bike.id
                            ? const Icon(Icons.check)
                            : null,
                        onTap: isSubmitting ? null : () => viewModel.selectBike(bike),
                      ),
                    ),
                ],
              );
            },
            error: (error, _) => ErrorStateView(
              message: 'Failed to load bikes.',
              onRetry: viewModel.retry,
            ),
            loading: () => const LoadingView(message: 'Loading bikes…'),
          ),
          const SizedBox(height: 20),
          Text(
            'Listing Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _startingBidController,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Starting Bid (MYR)'),
                  validator: Validators.listingStartingBid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buyoutController,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Buyout Price (MYR)'),
                  validator: (v) => Validators.listingBuyoutPrice(
                    buyoutValue: v,
                    startingBid: startingBid,
                  ),
                ),
                const SizedBox(height: 12),
                _DurationPicker(
                  preset: _preset,
                  enabled: !isSubmitting,
                  onChanged: (p) => setState(() => _preset = p),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Listing Notes'),
                  minLines: 2,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final isValid = _formKey.currentState?.validate() ?? false;
                            if (!isValid) return;
                            if (state.selectedBike == null) {
                              AppSnackbar.showError(context, 'Select a bike model first.');
                              return;
                            }
                            if (_preset == null) {
                              AppSnackbar.showError(context, 'Closing preset required.');
                              return;
                            }

                            final start = double.parse(_startingBidController.text.trim());
                            final buyout = double.parse(_buyoutController.text.trim());

                            final listingId = await viewModel.publishListing(
                              startingBid: start,
                              buyOutPrice: buyout,
                              preset: _preset!,
                              listingComments: _notesController.text,
                            );

                            if (!context.mounted) return;
                            if (listingId == null) {
                              final mutation = ref.read(createListingViewModelProvider).mutation;
                              final err = mutation.error;
                              if (err != null) {
                                AppSnackbar.showError(context, err.toString());
                              }
                              return;
                            }

                            AppSnackbar.showSuccess(context, 'Listing published');
                            context.go('/listing/$listingId');
                          },
                    icon: const Icon(Icons.publish),
                    label: Text(isSubmitting ? 'Publishing…' : 'Publish Listing'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedBikeCard extends StatelessWidget {
  const _SelectedBikeCard({required this.bike, required this.onClear});

  final Bike? bike;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (bike == null) {
      return const EmptyStateView(
        message: 'No bike selected. Search and pick one below.',
        icon: Icons.motorcycle,
      );
    }

    return Card(
      child: ListTile(
        title: Text(bike!.title),
        subtitle: Text('${bike!.brandLabel} · ${bike!.category} · ${bike!.displacementBucket}'),
        trailing: IconButton(
          tooltip: 'Clear selection',
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.preset,
    required this.enabled,
    required this.onChanged,
  });

  final ListingDurationPreset? preset;
  final bool enabled;
  final ValueChanged<ListingDurationPreset?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Closing In', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in ListingDurationPreset.values)
              ChoiceChip(
                label: Text(p.label),
                selected: preset == p,
                onSelected: enabled ? (_) => onChanged(p) : null,
              ),
          ],
        ),
      ],
    );
  }
}
