import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/swimiq_theme.dart';
import 'router/app_router.dart';

class SwimIQApp extends ConsumerWidget {
  const SwimIQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: SwimIQTheme.light,
      routerConfig: router,
    );
  }
}
