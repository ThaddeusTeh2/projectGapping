import 'package:flutter/material.dart';

import '../../core/ui/app_scaffold.dart';

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Listing',
      body: ListView(
        children: const [
          Text('Placeholder — implement bike picker + form on Day 5.'),
        ],
      ),
    );
  }
}
