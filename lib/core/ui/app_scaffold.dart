// Consistent scaffold wrapper for screens.
// Responsibilities:
// - Standard padding and layout conventions
// - Optional app bar/header
// - Surface global snackbars/toasts

import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.padding,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), leading: leading, actions: actions),
      body: Padding(padding: padding ?? const EdgeInsets.all(16), child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
