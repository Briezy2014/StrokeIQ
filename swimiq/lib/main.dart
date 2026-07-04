import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironment();

  runApp(const SwimIQApp());
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
    Env.loadFromDotenv(dotenv.env);
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        'SwimIQ: .env not found — use --dart-define for SUPABASE_URL and '
        'SUPABASE_ANON_KEY in release builds.',
      );
    }
  }
}
