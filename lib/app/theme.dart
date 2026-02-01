// App theme definitions.
// Responsibilities:
// - Material 3 base theme
// - shadcn_ui tokens (colors/typography/radius)
// - Shared spacing + text styles used across features

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
	AppTheme._();

	static const String fontFamilyMono = 'JetBrainsMono';

	static const BorderRadius shadRadius = BorderRadius.all(Radius.circular(6));

	static ShadThemeData shadOledDark() {
		final hotWhiteBorder = ShadBorder.all(
			color: Colors.white,
			width: 1,
		);

		final baseScheme = ShadColorScheme.fromName(
			'zinc',
			brightness: Brightness.dark,
		);

		final oledScheme = baseScheme.copyWith(
			background: Colors.black,
			foreground: Colors.white,
			card: const Color(0xFF050505),
			cardForeground: Colors.white,
			popover: const Color(0xFF0A0A0A),
			popoverForeground: Colors.white,
			primary: Colors.white,
			primaryForeground: Colors.black,
			secondary: const Color(0xFF0F0F0F),
			secondaryForeground: Colors.white,
			muted: const Color(0xFF0F0F0F),
			mutedForeground: const Color(0xFFB3B3B3),
			accent: const Color(0xFF141414),
			accentForeground: Colors.white,
			border: const Color(0xFF1F1F1F),
			input: const Color(0xFF1F1F1F),
			ring: Colors.white,
			selection: const Color(0xFF2563EB),
		);

		final textTheme = ShadTextTheme().apply(
			family: fontFamilyMono,
			fontFamilyFallback: const ['SF Mono', 'Menlo', 'monospace'],
		);

		return ShadThemeData(
			brightness: Brightness.dark,
			colorScheme: oledScheme,
			radius: shadRadius,
			textTheme: textTheme,
			cardTheme: ShadCardTheme(
				border: hotWhiteBorder,
			),
			inputTheme: ShadInputTheme(
				decoration: ShadDecoration(
					border: hotWhiteBorder,
					focusedBorder: hotWhiteBorder,
					errorBorder: hotWhiteBorder,
					secondaryBorder: hotWhiteBorder,
					secondaryFocusedBorder: hotWhiteBorder,
					secondaryErrorBorder: hotWhiteBorder,
				),
			),
		);
	}

	static ThemeData materialOledDark() {
		final base = ThemeData(
			useMaterial3: true,
			brightness: Brightness.dark,
			colorScheme: const ColorScheme.dark(
				primary: Colors.white,
				onPrimary: Colors.black,
				surface: Color(0xFF050505),
				onSurface: Colors.white,
				secondary: Color(0xFF141414),
				onSecondary: Colors.white,
				error: Color(0xFFEF4444),
				onError: Colors.white,
			),
			fontFamily: fontFamilyMono,
		);

		return base.copyWith(
			scaffoldBackgroundColor: Colors.black,
			cardTheme: base.cardTheme.copyWith(
				color: const Color(0xFF050505),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(6),
					side: const BorderSide(color: Color(0xFF1F1F1F)),
				),
			),
			appBarTheme: base.appBarTheme.copyWith(
				backgroundColor: Colors.black,
				foregroundColor: Colors.white,
				surfaceTintColor: Colors.transparent,
				centerTitle: false,
			),
			bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
				backgroundColor: Colors.black,
			),
			navigationBarTheme: base.navigationBarTheme.copyWith(
				backgroundColor: Colors.black,
				indicatorColor: const Color(0xFF141414),
				labelTextStyle: WidgetStatePropertyAll(
					base.textTheme.labelSmall?.copyWith(
						color: Colors.white,
					),
				),
				iconTheme: const WidgetStatePropertyAll(
					IconThemeData(color: Colors.white),
				),
			),
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(6),
					),
					backgroundColor: Colors.white,
					foregroundColor: Colors.black,
				),
			),
			outlinedButtonTheme: OutlinedButtonThemeData(
				style: OutlinedButton.styleFrom(
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(6),
					),
					side: const BorderSide(color: Color(0xFF1F1F1F)),
					foregroundColor: Colors.white,
				),
			),
			inputDecorationTheme: base.inputDecorationTheme.copyWith(
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(6),
					borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(6),
					borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(6),
					borderSide: const BorderSide(color: Colors.white),
				),
			),
		);
	}

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
