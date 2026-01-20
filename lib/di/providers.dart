// Riverpod providers live here.
// Responsibilities:
// - Provide FirebaseAuth/FirebaseFirestore/FirebaseFunctions instances
// - Provide repositories
// - Provide auth state stream provider for router refresh
// - Provide ViewModel providers per screen

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
	return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
	return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
	return FirebaseFunctions.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
	return ref.watch(firebaseAuthProvider).authStateChanges();
});

final goRouterProvider = Provider<AppRouter>((ref) {
	final auth = ref.watch(firebaseAuthProvider);
	final refresh = ref.watch(routerRefreshListenableProvider(auth.authStateChanges()));
	return AppRouter(auth: auth, refreshListenable: refresh);
});

final routerRefreshListenableProvider = Provider.family<ChangeNotifier, Stream<dynamic>>((ref, stream) {
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
