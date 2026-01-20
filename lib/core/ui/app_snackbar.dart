// Snackbar/toast utilities.
// Responsibilities:
// - Standardize mutation feedback (success/failure)
// - Show permission-denied messages

import 'package:flutter/material.dart';

class AppSnackbar {
	AppSnackbar._();

	static void showError(BuildContext context, String message) {
		ScaffoldMessenger.of(context)
			..clearSnackBars()
			..showSnackBar(
				SnackBar(
					content: Text(message),
					backgroundColor: Theme.of(context).colorScheme.error,
				),
			);
	}

	static void showSuccess(BuildContext context, String message) {
		ScaffoldMessenger.of(context)
			..clearSnackBars()
			..showSnackBar(
				SnackBar(
					content: Text(message),
					backgroundColor: Theme.of(context).colorScheme.primary,
				),
			);
	}
}
