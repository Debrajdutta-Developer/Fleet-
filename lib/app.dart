import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

/// Root Application shell handling Theme injection and Routing coordination.
class FleetOSApp extends ConsumerWidget {
  const FleetOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FleetOS ERP',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Routing Configuration
      routerConfig: router,
    );
  }
}
