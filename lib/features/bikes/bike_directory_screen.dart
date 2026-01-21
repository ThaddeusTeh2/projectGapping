import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../data/repositories/bike_repository.dart';
import '../../domain/enums.dart';
import 'bike_directory_view_model.dart';

class BikeDirectoryScreen extends ConsumerWidget {
  const BikeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bikeDirectoryViewModelProvider);
    final viewModel = ref.read(bikeDirectoryViewModelProvider.notifier);

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
      title: 'Bikes',
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
                PopupMenuButton<BikeSort>(
                  tooltip: 'Sort',
                  onSelected: viewModel.setSort,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: BikeSort.titleAsc,
                      child: Text('Title (A–Z)'),
                    ),
                    PopupMenuItem(
                      value: BikeSort.dateCreatedDesc,
                      child: Text('Newest'),
                    ),
                    PopupMenuItem(
                      value: BikeSort.releaseYearDesc,
                      child: Text('Release year'),
                    ),
                  ],
                  child: const Chip(label: Text('Sort')),
                ),
                TextButton(
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
            child: state.bikes.when(
              data: (bikes) {
                if (bikes.isEmpty) {
                  return const EmptyStateView(message: 'No bikes found.');
                }

                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Bike directory (Day 3: filters + sort).'),
                    ),
                    for (final bike in bikes)
                      ListTile(
                        title: Text(bike.title),
                        subtitle: Text(
                          '${bike.brandLabel} · ${bike.category} · ${bike.displacementBucket}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/bike/${bike.id}'),
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
          ),
        ],
      ),
    );
  }
}
