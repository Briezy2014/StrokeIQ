import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

/// Dashboard placeholder — full metrics and charts come in the next milestone.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swimmerName = ref.watch(currentSwimmerNameProvider);
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${swimmerName ?? 'Swimmer'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Signed in as ${email ?? 'unknown'}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Your SwimIQ score, session stats, and progress charts '
                      'will appear here in the next milestone.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _ComingSoonCard(
              icon: Icons.show_chart,
              title: 'Progress charts',
              message: 'Time trends by stroke will be added soon.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}
