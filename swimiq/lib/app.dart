import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/swimmer_gate_screen.dart';

class SwimIqApp extends ConsumerWidget {
  const SwimIqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSwimmer = ref.watch(activeSwimmerProvider);

    return MaterialApp(
      title: 'SwimIQ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: activeSwimmer == null
          ? const SwimmerGateScreen()
          : const HomeScreen(),
    );
  }
}
