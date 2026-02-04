import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../di/providers.dart';
import '../../domain/models/bid.dart';
import '../../domain/models/shop_listing.dart';

import 'profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final profileAsync = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);

    return AppScaffold(
      title: 'Profile',
      actions: [
        Tooltip(
          message: 'Refresh',
          child: ShadIconButton.ghost(
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
      body: profileAsync.when(
        data: (profile) {
          return ListView(
            children: [
              Text('User: ${profile.email}'),
              const SizedBox(height: 4),
              if (auth.currentUser?.uid != null)
                Text(
                  'UID: ${auth.currentUser!.uid}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              ShadButton(
                onPressed: () async {
                  try {
                    await auth.signOut();
                  } catch (_) {
                    if (!context.mounted) return;
                    AppSnackbar.showError(context, 'Failed to sign out');
                  }
                },
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 24),
              Text(
                'My Listings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _MyListingsSection(listings: profile.myListings),
              const SizedBox(height: 24),
              Text('My Bids', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _MyBidsSection(bids: profile.myBids),
            ],
          );
        },
        error: (error, _) => ErrorStateView(
          message: _friendlyErrorMessage(error),
          onRetry: viewModel.retry,
        ),
        loading: () => const LoadingView(message: 'Loading profile…'),
      ),
    );
  }
}

class _MyListingsSection extends StatelessWidget {
  const _MyListingsSection({required this.listings});

  final List<ShopListing> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const EmptyStateView(message: 'No listings yet.');
    }

    return Column(
      children: [
        for (var i = 0; i < listings.length; i++) ...[
          ShadCard(
            child: ListTile(
              title: Text(listings[i].bikeTitle),
              subtitle: Text(
                '${listings[i].brandLabel} · ${listings[i].category} · ${listings[i].displacementBucket}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/listing/${listings[i].id}'),
            ),
          ),
          if (i != listings.length - 1)
            const ShadSeparator.horizontal(
              margin: EdgeInsets.symmetric(vertical: 8),
              thickness: 1,
            ),
        ],
      ],
    );
  }
}

class _MyBidsSection extends StatelessWidget {
  const _MyBidsSection({required this.bids});

  final List<Bid> bids;

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return const EmptyStateView(message: 'No bids yet.');
    }

    return Column(
      children: [
        for (var i = 0; i < bids.length; i++) ...[
          ShadCard(
            child: ListTile(
              title: Text('Bid: ${bids[i].amount.toStringAsFixed(0)}'),
              subtitle: Text('Listing: ${bids[i].listingId}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/listing/${bids[i].listingId}'),
            ),
          ),
          if (i != bids.length - 1)
            const ShadSeparator.horizontal(
              margin: EdgeInsets.symmetric(vertical: 8),
              thickness: 1,
            ),
        ],
      ],
    );
  }
}

String _friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Permission denied.';
  }
  if (text.contains('unavailable')) {
    return 'Network error. Please check your connection.';
  }
  if (text.contains('signed in') || text.contains('signed')) {
    return 'You must be signed in.';
  }
  return 'Failed to load profile.';
}
