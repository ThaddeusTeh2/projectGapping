// Standard empty state widget.
// Responsibilities:
// - Used by bikes list, comments list, listings list, profile lists

import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
	const EmptyStateView({super.key, required this.message, this.icon});

	final String message;
	final IconData? icon;

	@override
	Widget build(BuildContext context) {
		final color = Theme.of(context).colorScheme.onSurfaceVariant;
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(24),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(icon ?? Icons.inbox_outlined, size: 40, color: color),
						const SizedBox(height: 12),
						Text(
							message,
							textAlign: TextAlign.center,
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
						),
					],
				),
			),
		);
	}
}
