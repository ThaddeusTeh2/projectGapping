import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../di/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final email = auth.currentUser?.email ?? '(unknown)';

    return AppScaffold(
      title: 'Profile',
      body: ListView(
        children: [
          Text('User: $email'),
          const SizedBox(height: 12),
          FilledButton(
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
          const Text('My Listings (placeholder — Day 4).'),
          const SizedBox(height: 12),
          const Text('My Bids (placeholder — Day 4).'),
        ],
      ),
    );
  }
}
