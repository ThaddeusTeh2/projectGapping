// Snackbar/toast utilities.
// Responsibilities:
// - Standardize mutation feedback (success/failure)
// - Show permission-denied messages

import 'package:flutter/material.dart';

class AppSnackbar {
	AppSnackbar._();

	/// Root messenger for cases where the calling [BuildContext] does not have a
	/// [ScaffoldMessenger] above it (e.g. nested navigators, bottom sheets).
	static final GlobalKey<ScaffoldMessengerState> messengerKey =
		GlobalKey<ScaffoldMessengerState>();

	static void showError(BuildContext context, String message) {
		final messenger = messengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
		if (messenger == null) {
			// Some app shells (or test harnesses) may not provide a ScaffoldMessenger.
			// Avoid crashing and at least surface the error in logs.
			debugPrint('SnackBar error (no ScaffoldMessenger): $message');
			return;
		}

		messenger
			..clearSnackBars()
			..showSnackBar(
				SnackBar(
					content: Text(message),
					backgroundColor: Theme.of(context).colorScheme.error,
				),
			);
	}

	static void showSuccess(BuildContext context, String message) {
		final messenger = messengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
		if (messenger == null) {
			debugPrint('SnackBar success (no ScaffoldMessenger): $message');
			return;
		}

		messenger
			..clearSnackBars()
			..showSnackBar(
				SnackBar(
					content: Text(message),
					backgroundColor: Theme.of(context).colorScheme.primary,
				),
			);
	}
}
