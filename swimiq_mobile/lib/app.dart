import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/placeholder_home_screen.dart';

/// Root router for SwimIQ Version 1.
///
/// Auth and feature routes will be added in the next milestone.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderHomeScreen(),
    ),
  ],
);

class SwimIqApp extends ConsumerWidget {
  const SwimIqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildSwimIqTheme(),
      routerConfig: appRouter,
    );
  }
}
