// App root (MaterialApp.router) will live here.
// Responsibilities:
// - Build Material 3 + shadcn_ui theme integration
// - Provide router config
// - Global app-level scaffolding defaults

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/ui/app_snackbar.dart';
import '../di/providers.dart';
import 'theme.dart';

class App extends ConsumerWidget {
	const App({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final appRouter = ref.watch(goRouterProvider);

		return ScaffoldMessenger(
			key: AppSnackbar.messengerKey,
			child: ShadApp.router(
				debugShowCheckedModeBanner: false,
				title: 'Project Gapping',
				themeMode: ThemeMode.dark,
				darkTheme: AppTheme.shadOledDark(),
				materialThemeBuilder: (context, theme) => AppTheme.materialOledDark(),
				routerConfig: appRouter.router,
			),
		);
	}
}
