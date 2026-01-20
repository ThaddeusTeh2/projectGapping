import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../di/providers.dart';
import '../../domain/models/bike.dart';

final _bikesProvider = FutureProvider.autoDispose<List<Bike>>((ref) {
  return ref.watch(bikeRepositoryProvider).listBikes(limit: 40);
});

class BikeDirectoryScreen extends ConsumerWidget {
  const BikeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(_bikesProvider);

    return AppScaffold(
      title: 'Bikes',
      body: bikesAsync.when(
        data: (bikes) {
          if (bikes.isEmpty) {
            return const EmptyStateView(message: 'No bikes found.');
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Bike directory (Day 2: repo read sanity check).'),
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
          onRetry: () => ref.invalidate(_bikesProvider),
        ),
        loading: () => const LoadingView(message: 'Loading bikes…'),
      ),
    );
  }
}
