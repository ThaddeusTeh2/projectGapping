import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
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

    ref.listen(createListingViewModelProvider.select((s) => s.mutation), (
      previous,
      next,
    ) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(context, next.error.toString());
      }
    });

    final isSubmitting = state.mutation.isLoading;
    final startingBid = double.tryParse(_startingBidController.text.trim());

    return AppScaffold(
      title: 'Create Listing',
      actions: [
        Tooltip(
          message: 'Reload bikes',
          child: ShadIconButton.ghost(
            onPressed: isSubmitting ? null : viewModel.retry,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
      body: ListView(
        children: [
          Text(
            'Select Bike Model',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          state.bikes.when(
            data: (bikes) {
              return _SelectedBikeCard(
                bike: state.selectedBike,
                enabled: !isSubmitting,
                onPick: () async {
                  final selected = await _showBikePicker(bikes: bikes);
                  if (!context.mounted) return;
                  if (selected != null) {
                    viewModel.selectBike(selected);
                  }
                },
                onClear: isSubmitting ? null : viewModel.clearSelection,
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
                ShadInputFormField(
                  controller: _startingBidController,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  label: const Text('Starting Bid (MYR)'),
                  validator: Validators.listingStartingBid,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _buyoutController,
                  enabled: !isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  label: const Text('Buyout Price (MYR)'),
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
                ShadInputFormField(
                  controller: _notesController,
                  enabled: !isSubmitting,
                  label: const Text('Listing Notes'),
                  minLines: 2,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final isValid =
                                _formKey.currentState?.validate() ?? false;
                            if (!isValid) return;
                            if (state.selectedBike == null) {
                              AppSnackbar.showError(
                                context,
                                'Select a bike model first.',
                              );
                              return;
                            }
                            if (_preset == null) {
                              AppSnackbar.showError(
                                context,
                                'Closing preset required.',
                              );
                              return;
                            }

                            final start = double.parse(
                              _startingBidController.text.trim(),
                            );
                            final buyout = double.parse(
                              _buyoutController.text.trim(),
                            );

                            final listingId = await viewModel.publishListing(
                              startingBid: start,
                              buyOutPrice: buyout,
                              preset: _preset!,
                              listingComments: _notesController.text,
                            );

                            if (!context.mounted) return;
                            if (listingId == null) {
                              final mutation = ref
                                  .read(createListingViewModelProvider)
                                  .mutation;
                              final err = mutation.error;
                              if (err != null) {
                                AppSnackbar.showError(context, err.toString());
                              }
                              return;
                            }

                            AppSnackbar.showSuccess(
                              context,
                              'Listing published',
                            );
                            context.go('/listing/$listingId');
                          },
                    leading: const Icon(Icons.publish),
                    child: Text(
                      isSubmitting ? 'Publishing…' : 'Publish Listing',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Bike?> _showBikePicker({required List<Bike> bikes}) async {
    _searchController.clear();
    return showModalBottomSheet<Bike?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var query = '';
        final selectedId = ref
            .read(createListingViewModelProvider)
            .selectedBike
            ?.id;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? bikes
                : bikes
                      .where(
                        (b) =>
                            b.titleLower.contains(q) ||
                            b.brandLabel.toLowerCase().contains(q),
                      )
                      .toList(growable: false);

            final visible = filtered.take(50).toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a bike',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ShadInputFormField(
                        controller: _searchController,
                        label: const Text('Search'),
                        placeholder: const Text('Type a model name…'),
                        onChanged: (v) => setModalState(() => query = v),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: visible.isEmpty
                            ? const EmptyStateView(
                                message: 'No bikes match your search.',
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final bike = visible[i];
                                  final isSelected = bike.id == selectedId;
                                  return ListTile(
                                    title: Text(bike.title),
                                    subtitle: Text(
                                      '${bike.brandLabel} · ${bike.category} · ${bike.displacementBucket}',
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.pop(context, bike),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SelectedBikeCard extends StatelessWidget {
  const _SelectedBikeCard({
    required this.bike,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final Bike? bike;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: ListTile(
        title: Text(bike?.title ?? 'Select a bike'),
        subtitle: bike == null
            ? const Text('Tap to search and pick a model')
            : Text(
                '${bike!.brandLabel} · ${bike!.category} · ${bike!.displacementBucket}',
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bike != null)
              Tooltip(
                message: 'Clear selection',
                child: ShadIconButton.ghost(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              ),
            const Icon(Icons.unfold_more),
          ],
        ),
        onTap: enabled ? onPick : null,
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
