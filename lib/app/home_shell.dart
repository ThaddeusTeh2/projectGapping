// Home shell (bottom tabs: Bikes / Shop / Profile).
// Responsibilities:
// - Render tab scaffold
// - Host nested navigation or tab switching
// - Provide consistent app header style

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
	const HomeShell({super.key, required this.navigationShell});

	final StatefulNavigationShell navigationShell;

	void _onTap(int index) {
		navigationShell.goBranch(
			index,
			initialLocation: index == navigationShell.currentIndex,
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: navigationShell,
			bottomNavigationBar: NavigationBar(
				selectedIndex: navigationShell.currentIndex,
				onDestinationSelected: _onTap,
				destinations: const [
					NavigationDestination(icon: Icon(Icons.motorcycle), label: 'Bikes'),
					NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
					NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
				],
			),
		);
	}
}
