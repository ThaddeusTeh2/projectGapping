// Riverpod providers live here.
// Responsibilities:
// - Provide FirebaseAuth/FirebaseFirestore instances
// - Provide repositories
// - Provide auth state stream provider for router refresh
// - Provide ViewModel providers per screen

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../data/firestore/firestore_auth_repository.dart';
import '../data/firestore/firestore_bid_repository.dart';
import '../data/firestore/firestore_bike_repository.dart';
import '../data/firestore/firestore_comment_repository.dart';
import '../data/firestore/firestore_listing_repository.dart';
import '../data/firestore/firestore_user_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/bid_repository.dart';
import '../data/repositories/bike_repository.dart';
import '../data/repositories/comment_repository.dart';
import '../data/repositories/listing_repository.dart';
import '../data/repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirestoreAuthRepository(auth: ref.watch(firebaseAuthProvider));
});

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  return FirestoreBikeRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return FirestoreCommentRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return FirestoreListingRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final bidRepositoryProvider = Provider<BidRepository>((ref) {
  return FirestoreBidRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

// Public display name lookup (public_users/{uid}).
final displayNameByUidProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, uid) {
      return ref.watch(userRepositoryProvider).getPublicDisplayName(uid);
    });

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final goRouterProvider = Provider<AppRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final refresh = ref.watch(
    routerRefreshListenableProvider(auth.authStateChanges()),
  );
  return AppRouter(auth: auth, refreshListenable: refresh);
});

final routerRefreshListenableProvider =
    Provider.family<ChangeNotifier, Stream<dynamic>>((ref, stream) {
      final notifier = GoRouterRefreshStream(stream);
      ref.onDispose(notifier.dispose);
      return notifier;
    });

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
