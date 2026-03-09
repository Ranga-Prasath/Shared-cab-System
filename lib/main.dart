// -- Shared Cab System --
// Main entry point

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_cab/firebase_options.dart';
import 'package:shared_cab/core/router/app_router.dart';
import 'package:shared_cab/core/theme/app_theme.dart';
import 'package:shared_cab/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SharedCabApp()));
}

class SharedCabApp extends ConsumerWidget {
  const SharedCabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNightMode = ref.watch(effectiveNightModeProvider);

    return MaterialApp.router(
      title: 'Shared Cab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.night,
      themeMode: isNightMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}

