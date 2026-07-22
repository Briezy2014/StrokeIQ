import 'package:flutter/material.dart';

import '../core/constants/legal_constants.dart';
import '../screens/legal/legal_document_screen.dart';
import 'swimiq_header.dart';

class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade700,
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            'Legal & privacy',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _LegalLink(
              label: 'Privacy Policy',
              document: LegalDocumentType.privacyPolicy,
            ),
            _LegalLink(
              label: 'Terms of Service',
              document: LegalDocumentType.termsOfService,
            ),
            _LegalLink(
              label: 'AI & Data Disclosure',
              document: LegalDocumentType.aiDataDisclosure,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwimIqCopyrightLine(compact: compact),
        const SizedBox(height: 6),
        Text(
          compact ? LegalConstants.compactFooter : LegalConstants.settingsFooter,
          style: style,
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.document,
  });

  final String label;
  final LegalDocumentType document;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LegalDocumentScreen(document: document),
          ),
        );
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
