import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/routes/app_router.dart';
import 'package:mobile_frontend/theme/app_theme.dart'; // Your theme file

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Workflow App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Connect GoRouter
      routerConfig: router,
    );
  }
}