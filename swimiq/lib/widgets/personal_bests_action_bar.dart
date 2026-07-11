import 'package:flutter/material.dart';

import '../screens/membership/membership_screen.dart';
import 'personal_best_upload_sheet.dart';

class PersonalBestsActionBar extends StatelessWidget {
  const PersonalBestsActionBar({
    super.key,
    required this.showOfficial,
  });

  final bool showOfficial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (showOfficial) ...[
              FilledButton.icon(
                onPressed: () => showPersonalBestUploadSheet(context),
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: const Text('Upload best times'),
              ),
              OutlinedButton.icon(
                onPressed: () => showPersonalBestUploadSheet(
                  context,
                  startWithPhotoPicker: true,
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Upload times photo'),
              ),
            ] else
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                ),
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: const Text('Upload best times'),
              ),
          ],
        ),
      ),
    );
  }
}
