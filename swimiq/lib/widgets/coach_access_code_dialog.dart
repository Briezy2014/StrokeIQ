import 'package:flutter/material.dart';

import '../core/models/subscription_plan.dart';

/// Prompt for a coach access code before granting coach preview.
Future<String?> showCoachAccessCodeDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _CoachAccessCodeDialog(),
  );
}

class _CoachAccessCodeDialog extends StatefulWidget {
  const _CoachAccessCodeDialog();

  @override
  State<_CoachAccessCodeDialog> createState() => _CoachAccessCodeDialogState();
}

class _CoachAccessCodeDialogState extends State<_CoachAccessCodeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the coach access code SwimIQ gave you.');
      return;
    }
    if (!SubscriptionCatalog.isCoachAccessCode(code)) {
      setState(() => _error = 'That code is not valid. Check with your SwimIQ contact.');
      return;
    }
    Navigator.pop(context, code.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coach access'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the coach access code you received from SwimIQ. '
              'You will create your own account (or sign in) — the code unlocks '
              '${SubscriptionCatalog.coachTrialDays}-day Pro access and a '
              '${SubscriptionCatalog.coachElitePeekDays}-day Elite AI preview.',
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Coach access code',
                hintText: 'Enter code from SwimIQ',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
