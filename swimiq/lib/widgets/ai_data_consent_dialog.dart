import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/legal_constants.dart';
import 'legal_footer.dart';

class AiDataConsentDialog extends StatelessWidget {
  const AiDataConsentDialog({super.key});

  static Future<bool> ensureGranted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(LegalConstants.aiConsentStorageKey) == true) {
      return true;
    }

    if (!context.mounted) return false;
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AiDataConsentDialog(),
    );
    if (granted == true) {
      await prefs.setBool(LegalConstants.aiConsentStorageKey, true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('SwimIQ AI data disclosure'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before SwimIQ analyzes your video, please confirm you understand '
              'how your data is used:',
            ),
            const SizedBox(height: 12),
            const Text(
              '• Your swim video and related profile context (event, notes, goals) '
              'are sent to SwimIQ secure servers.\n'
              '• SwimIQ uses Google cloud AI to generate kid- and parent-friendly '
              'swim coaching feedback (technique only — not medical advice).\n'
              '• Output is AI-generated estimates — not official timing or medical advice.\n'
              '• You can revoke consent anytime in Settings (sign out clears local consent).',
            ),
            const SizedBox(height: 12),
            const LegalFooter(compact: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('I agree — run AI analysis'),
        ),
      ],
    );
  }
}
