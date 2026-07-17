import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironment();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } else if (kDebugMode) {
    debugPrint(
      'SwimIQ: Supabase not configured. Copy .env.example to .env or use '
      '--dart-define.',
    );
  }

  runApp(
    const ProviderScope(
      child: SwimIqApp(),
    ),
  );
}

Future<void> _loadEnvironment() async {
  try {
    // Optional local file load (mobile/desktop). Flutter web Chrome launches
    // should pass --dart-define from START-SWIMIQ.bat / start_swimiq.ps1.
    await dotenv.load(fileName: '.env', isOptional: true);
    Env.loadFromDotenv(dotenv.env);
  } catch (_) {
    // dart-define values are used when .env is unavailable.
  }
}
