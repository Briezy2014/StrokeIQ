import 'package:flutter/material.dart';

import '../config/theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: SwimIQTheme.accentBlue,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
