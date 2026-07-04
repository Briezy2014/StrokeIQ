import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/swimmer_login_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const ProviderScope(child: SwimIQApp()));
}

class SwimIQApp extends ConsumerStatefulWidget {
  const SwimIQApp({super.key});

  @override
  ConsumerState<SwimIQApp> createState() => _SwimIQAppState();
}

class _SwimIQAppState extends ConsumerState<SwimIQApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(activeSwimmerProvider.notifier).loadSaved(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSwimmer = ref.watch(activeSwimmerProvider);

    return MaterialApp(
      title: 'SwimIQ',
      debugShowCheckedModeBanner: false,
      theme: SwimIQTheme.light(),
      home: activeSwimmer == null || activeSwimmer.isEmpty
          ? const SwimmerLoginScreen()
          : const HomeScreen(),
    );
  }
}
