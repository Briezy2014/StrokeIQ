import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_constants.dart';

/// One-tap email to request account deletion (Play Console data-safety URL).
class PublicDeleteAccountScreen extends StatelessWidget {
  const PublicDeleteAccountScreen({super.key});

  Future<void> _emailDeletionRequest() async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalConstants.contactEmail,
      query:
          'subject=${Uri.encodeComponent('Delete my SwimIQ account')}&body=${Uri.encodeComponent('Please delete my SwimIQ account and all my data.\n\nMy account email: \n')}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SwimIQ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Delete your account',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the button below. Your email app opens with a pre-filled message. '
              'Send it — we delete your account and data within 30 days.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _emailDeletionRequest,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                'Request account deletion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Or email ${LegalConstants.contactEmail}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
