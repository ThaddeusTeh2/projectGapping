import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../data/repositories/bike_repository.dart';
import '../../domain/enums.dart';
import 'bike_directory_view_model.dart';

class BikeDirectoryScreen extends ConsumerStatefulWidget {
  const BikeDirectoryScreen({super.key});

  @override
  ConsumerState<BikeDirectoryScreen> createState() =>
      _BikeDirectoryScreenState();
}

class _BikeDirectoryScreenState extends ConsumerState<BikeDirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final canClear =
        state.brandKey != null ||
        state.category != null ||
        state.displacementBucket != null ||
        state.query.trim().isNotEmpty;

    return AppScaffold(
      title: 'Bikes',
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
                      onPressed: state.sort == BikeSort.titleAsc
                          ? null
                          : () => viewModel.setSort(BikeSort.titleAsc),
                      child: Text(
                        '${state.sort == BikeSort.titleAsc ? '✓ ' : ''}Title',
                      ),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: state.sort == BikeSort.dateCreatedDesc
                          ? null
                          : () => viewModel.setSort(BikeSort.dateCreatedDesc),
                      child: Text(
                        '${state.sort == BikeSort.dateCreatedDesc ? '✓ ' : ''}Newest',
                      ),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: state.sort == BikeSort.releaseYearDesc
                          ? null
                          : () => viewModel.setSort(BikeSort.releaseYearDesc),
                      child: Text(
                        '${state.sort == BikeSort.releaseYearDesc ? '✓ ' : ''}Year',
                      ),
                    ),
                  ],
                ),
              ],
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
                    for (var i = 0; i < bikes.length; i++) ...[
                      ListTile(
                        title: Text(bikes[i].title),
                        subtitle: Text(
                          '${bikes[i].brandLabel} · ${bikes[i].category} · ${bikes[i].displacementBucket}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/bike/${bikes[i].id}'),
                      ),
                      if (i != bikes.length - 1) const Divider(height: 1),
                    ],
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
