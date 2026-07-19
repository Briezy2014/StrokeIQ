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
        child: Center(
          child: FilledButton.icon(
            onPressed: () {
              if (showOfficial) {
                showPersonalBestUploadChooser(context);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MembershipScreen(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Upload best times'),
          ),
        ),
      ),
    );
  }
}
