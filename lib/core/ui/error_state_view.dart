// Standard error state widget.
// Responsibilities:
// - Show error message + retry button callback
// - Used for network failure handling requirement

import 'package:flutter/material.dart';

class ErrorStateView extends StatelessWidget {
	const ErrorStateView({
		super.key,
		required this.message,
		required this.onRetry,
	});

	final String message;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(24),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(Icons.wifi_off_outlined, size: 40, color: Theme.of(context).colorScheme.error),
						const SizedBox(height: 12),
						Text(message, textAlign: TextAlign.center),
						const SizedBox(height: 12),
						FilledButton(onPressed: onRetry, child: const Text('Retry')),
					],
				),
			),
		);
	}
}
