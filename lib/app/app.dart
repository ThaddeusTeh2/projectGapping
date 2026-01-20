// App root (MaterialApp.router) will live here.
// Responsibilities:
// - Build Material 3 + shadcn_ui theme integration
// - Provide router config
// - Global app-level scaffolding defaults

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'theme.dart';

class App extends ConsumerWidget {
	const App({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final appRouter = ref.watch(goRouterProvider);

		return MaterialApp.router(
			debugShowCheckedModeBanner: false,
			title: 'Project Gapping',
			theme: AppTheme.light(),
			routerConfig: appRouter.router,
		);
	}
}
