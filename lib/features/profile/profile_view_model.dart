import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../di/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/bid.dart';
import '../../domain/models/shop_listing.dart';

class ProfileData {
  const ProfileData({
    required this.displayName,
    required this.email,
    required this.user,
    required this.myListings,
    required this.myBids,
  });

  final String displayName;
  final String email;
  final AppUser? user;
  final List<ShopListing> myListings;
  final List<Bid> myBids;
}

final profileViewModelProvider =
    NotifierProvider.autoDispose<ProfileViewModel, AsyncValue<ProfileData>>(
      ProfileViewModel.new,
    );

class ProfileViewModel extends AutoDisposeNotifier<AsyncValue<ProfileData>> {
  @override
  AsyncValue<ProfileData> build() {
    // Rebuild when auth state changes, so the profile reacts to sign-in/out.
    ref.watch(authStateChangesProvider);

    state = const AsyncLoading();
    Future.microtask(_fetch);
    return state;
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final auth = ref.read(firebaseAuthProvider);
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw StateError('You must be signed in.');
      }

      final uid = currentUser.uid;
      final email = currentUser.email ?? '(unknown)';

      String defaultDisplayName() {
        final trimmed = email.trim();
        final at = trimmed.indexOf('@');
        if (at > 0) {
          final prefix = trimmed.substring(0, at);
          final safe = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '');
          final v = safe.trim();
          if (v.length >= 3) {
            return v.length <= 24 ? v : v.substring(0, 24);
          }
        }
        final short = uid.length <= 8
            ? uid
            : '${uid.substring(0, 4)}…${uid.substring(uid.length - 4)}';
        return 'rider $short';
      }

      final userRepo = ref.read(userRepositoryProvider);

      // Ensure minimal user doc exists; safe to call on every refresh.
      final createdMillis =
          currentUser.metadata.creationTime?.millisecondsSinceEpoch ??
          nowMillis();
      await userRepo.ensureUserDoc(
        userId: uid,
        userDateCreatedMillis: createdMillis,
      );

      // Best-effort: ensure public profile exists for UID -> displayName lookup.
      final now = nowMillis();
      try {
        await userRepo.ensurePublicUserDoc(
          userId: uid,
          defaultDisplayName: defaultDisplayName(),
          updatedAtMillis: now,
        );
      } catch (_) {
        // Keep profile usable even if this fails (offline/rules misconfig).
      }

      final userFuture = userRepo.getUserById(uid);
      final listingsFuture = userRepo.listMyListings(uid, limit: 50);
      final bidsFuture = userRepo.listMyBids(uid, limit: 50);
      final displayNameFuture = userRepo.getPublicDisplayName(uid);

      final user = await userFuture;
      final myListings = await listingsFuture;
      final myBids = await bidsFuture;
      final displayName = await displayNameFuture;

      final sortedListings = List<ShopListing>.of(myListings)
        ..sort((a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis));
      final sortedBids = List<Bid>.of(myBids)
        ..sort((a, b) => b.dateCreatedMillis.compareTo(a.dateCreatedMillis));

      return ProfileData(
        displayName: displayName ?? defaultDisplayName(),
        email: email,
        user: user,
        myListings: sortedListings,
        myBids: sortedBids,
      );
    });

    state = result;
  }

  Future<void> retry() => _fetch();

  Future<void> refresh() => _fetch();

  Future<void> updateDisplayName(String displayName) async {
    final v = displayName.trim();
    if (v.isEmpty) throw StateError('Display name is required.');

    final auth = ref.read(firebaseAuthProvider);
    final currentUser = auth.currentUser;
    if (currentUser == null) throw StateError('You must be signed in.');

    await ref
        .read(userRepositoryProvider)
        .setPublicDisplayName(
          userId: currentUser.uid,
          displayName: v,
          updatedAtMillis: nowMillis(),
        );

    await _fetch();
  }
}
