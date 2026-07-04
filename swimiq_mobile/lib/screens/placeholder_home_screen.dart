import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../core/supabase_config.dart';

/// Temporary home screen shown after the Flutter project scaffold is created.
///
/// This will be replaced by Splash → Auth → Dashboard in the next milestone.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final hasSession = supabase.auth.currentSession != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.pool,
              size: 72,
              color: Color(0xFF009CFF),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0077C8),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 3 complete',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Flutter project scaffold is ready. Supabase is initialized. '
                      'Next up: splash screen, login, and sign-up.',
                    ),
                    const SizedBox(height: 12),
                    Text('Supabase URL: ${SupabaseConfig.url}'),
                    const SizedBox(height: 4),
                    Text(
                      'Auth session: ${hasSession ? 'signed in' : 'not signed in'}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
