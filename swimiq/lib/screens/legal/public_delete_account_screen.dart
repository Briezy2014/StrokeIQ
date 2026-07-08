import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_constants.dart';
import '../../widgets/legal_footer.dart';

/// Public page for Play Console data-deletion URL (no login required).
class PublicDeleteAccountScreen extends StatelessWidget {
  const PublicDeleteAccountScreen({super.key});

  Future<void> _emailDeletionRequest() async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalConstants.contactEmail,
      query:
          'subject=${Uri.encodeComponent('SwimIQ account deletion request')}&body=${Uri.encodeComponent('Please delete my SwimIQ account and associated data.\n\nAccount email: \nDisplay name (if any): \n\nI confirm I want this account and data permanently deleted.')}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete account & data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Request deletion of your SwimIQ account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You can request deletion of your SwimIQ account and the personal data '
            'we store for that account. We verify you control the account, then delete '
            'eligible data within 30 days.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _emailDeletionRequest,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Email deletion request'),
          ),
          const SizedBox(height: 24),
          Text(
            'What we delete',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Your sign-in account\n'
            '• Athlete profile information\n'
            '• Training logs, meet results, goals, and personal bests\n'
            '• Uploaded swim videos and AI analysis tied to your account\n'
            '• Subscription records for your account',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          Text(
            'How to request',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Email ${LegalConstants.contactEmail} from the address on your SwimIQ account.\n\n'
            'Subject: SwimIQ account deletion request\n\n'
            'Include your account email, athlete/display name, and confirmation that '
            'you want deletion.\n\n'
            'For accounts under age 13, a parent or guardian must send the request.\n\n'
            'You may also email ${LegalConstants.supportEmail}.',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 28),
          const LegalFooter(),
        ],
      ),
    );
  }
}
