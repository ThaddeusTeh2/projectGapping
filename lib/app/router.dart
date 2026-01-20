// go_router configuration lives here.
// Responsibilities:
// - Define routes from SSOT:
//   /login, /register, /home, /bikes, /bike/:id, /shop, /listing/:id, /listing/create, /profile
// - Auth redirect (unauthenticated -> /login)
// - Optional: nested navigation for Home tabs

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/bikes/bike_detail_screen.dart';
import '../features/bikes/bike_directory_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shop/create_listing_screen.dart';
import '../features/shop/listing_detail_screen.dart';
import '../features/shop/shop_directory_screen.dart';
import 'home_shell.dart';

class AppRouter {
	AppRouter({required FirebaseAuth auth, required Listenable refreshListenable})
			: router = GoRouter(
					initialLocation: '/login',
					refreshListenable: refreshListenable,
					redirect: (context, state) {
						final isLoggedIn = auth.currentUser != null;
						final location = state.matchedLocation;
						final isAuthRoute = location == '/login' || location == '/register';

						if (!isLoggedIn && !isAuthRoute) return '/login';
						if (isLoggedIn && isAuthRoute) return '/bikes';
						return null;
					},
					routes: [
						GoRoute(
							path: '/login',
							builder: (context, state) => const LoginScreen(),
						),
						GoRoute(
							path: '/register',
							builder: (context, state) => const RegisterScreen(),
						),
						GoRoute(
							path: '/home',
							redirect: (context, state) => '/bikes',
						),
						StatefulShellRoute.indexedStack(
							builder: (context, state, navigationShell) {
								return HomeShell(navigationShell: navigationShell);
							},
							branches: [
								StatefulShellBranch(
									routes: [
										GoRoute(
											path: '/bikes',
											builder: (context, state) => const BikeDirectoryScreen(),
										),
										GoRoute(
											path: '/bike/:id',
											builder: (context, state) {
												final id = state.pathParameters['id'] ?? '';
												return BikeDetailScreen(bikeId: id);
											},
										),
									],
								),
								StatefulShellBranch(
									routes: [
										GoRoute(
											path: '/shop',
											builder: (context, state) => const ShopDirectoryScreen(),
										),
										GoRoute(
											path: '/listing/create',
											builder: (context, state) => const CreateListingScreen(),
										),
										GoRoute(
											path: '/listing/:id',
											builder: (context, state) {
												final id = state.pathParameters['id'] ?? '';
												return ListingDetailScreen(listingId: id);
											},
										),
									],
								),
								StatefulShellBranch(
									routes: [
										GoRoute(
											path: '/profile',
											builder: (context, state) => const ProfileScreen(),
										),
									],
								),
							],
						),
					],
				);

	final GoRouter router;
}
