import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import 'add_comment_sheet.dart';
import 'bike_detail_view_model.dart';

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({super.key, required this.bikeId});

  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bikeDetailViewModelProvider(bikeId));
    final viewModel = ref.read(bikeDetailViewModelProvider(bikeId).notifier);

    ref.listen(bikeDetailViewModelProvider(bikeId).select((s) => s.mutation), (
      previous,
      next,
    ) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(context, next.error.toString());
      }
    });

    final commentsAsync = ref.watch(bikeCommentsProvider(bikeId));

    return AppScaffold(
      title: 'Bike Detail',
      body: state.bike.when(
        data: (bike) {
          if (bike == null) {
            return ErrorStateView(
              message: 'Bike not found.',
              onRetry: viewModel.retry,
            );
          }

          return ListView(
            children: [
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bike.brandLabel} · ${bike.category} · ${bike.displacementCc}cc · ${bike.releaseYear}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(bike.desc),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEA Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _kvText('Pricing', bike.seaPricingNote),
                      _kvText('Fuel', bike.seaFuelNote),
                      _kvText('Parts', bike.seaPartsNote),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => AddCommentSheet(bikeId: bikeId),
                        );
                      },
                      leading: const Icon(Icons.add_comment),
                      child: const Text('Add comment'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Comments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return const EmptyStateView(message: 'No comments yet.');
                  }

                  return Column(
                    children: [
                      for (final c in comments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShadCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.commentTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'User ID: ${c.userId}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.comment),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Tooltip(
                                        message: 'Upvote',
                                        child: ShadIconButton.ghost(
                                          onPressed: () =>
                                              viewModel.upvoteComment(c.id),
                                          icon: const Icon(Icons.thumb_up),
                                        ),
                                      ),
                                      Text('${c.upvoteCount}'),
                                      const SizedBox(width: 12),
                                      Tooltip(
                                        message: 'Downvote',
                                        child: ShadIconButton.ghost(
                                          onPressed: () =>
                                              viewModel.downvoteComment(c.id),
                                          icon: const Icon(Icons.thumb_down),
                                        ),
                                      ),
                                      Text('${c.downvoteCount}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => ErrorStateView(
                  message: 'Failed to load comments.',
                  onRetry: () => ref.invalidate(bikeCommentsProvider(bikeId)),
                ),
                loading: () => const LoadingView(message: 'Loading comments…'),
              ),
            ],
          );
        },
        error: (error, _) => ErrorStateView(
          message: 'Failed to load bike.',
          onRetry: viewModel.retry,
        ),
        loading: () => const LoadingView(message: 'Loading bike…'),
      ),
    );
  }
}

Widget _kvText(String label, String value) {
  final v = value.trim().isEmpty ? '(none)' : value.trim();
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text('$label: $v'),
  );
}
