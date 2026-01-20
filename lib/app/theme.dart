// App theme definitions.
// Responsibilities:
// - Material 3 base theme
// - shadcn_ui tokens (colors/typography/radius)
// - Shared spacing + text styles used across features

import 'package:flutter/material.dart';

class AppTheme {
	AppTheme._();

	static ThemeData light() {
		final base = ThemeData(
			useMaterial3: true,
			colorSchemeSeed: const Color(0xFF7C3AED),
			brightness: Brightness.light,
		);

		return base.copyWith(
			appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
			inputDecorationTheme: base.inputDecorationTheme.copyWith(
				border: const OutlineInputBorder(),
			),
		);
	}
}
