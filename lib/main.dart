import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final app = Firebase.app();
  debugPrint(
    'Firebase initialized: projectId=${app.options.projectId} appId=${app.options.appId}',
  );
  runApp(const ProviderScope(child: App()));
}

