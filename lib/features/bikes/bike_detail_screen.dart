import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../di/providers.dart';
import '../../domain/models/bike.dart';

final _bikeProvider = FutureProvider.autoDispose.family<Bike?, String>((
  ref,
  bikeId,
) {
  return ref.watch(bikeRepositoryProvider).getBikeById(bikeId);
});

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({super.key, required this.bikeId});

  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeAsync = ref.watch(_bikeProvider(bikeId));

    return AppScaffold(
      title: 'Bike Detail',
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return ErrorStateView(
              message: 'Bike not found.',
              onRetry: () => ref.invalidate(_bikeProvider(bikeId)),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bike.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${bike.brandLabel} · ${bike.category} · ${bike.displacementCc}cc',
              ),
              const SizedBox(height: 12),
              const Text(
                'Placeholder — implement specs + SEA notes + comments on Day 3.',
              ),
            ],
          );
        },
        error: (error, _) => ErrorStateView(
          message: 'Failed to load bike.',
          onRetry: () => ref.invalidate(_bikeProvider(bikeId)),
        ),
        loading: () => const LoadingView(message: 'Loading bike…'),
      ),
    );
  }
}
