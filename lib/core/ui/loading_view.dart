// Standard loading state widget.
// Responsibilities:
// - Show spinner/skeleton consistent with shadcn styling

import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label, this.message});

  final String? label;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message ?? label;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (text != null) ...[const SizedBox(height: 12), Text(text)],
        ],
      ),
    );
  }
}
