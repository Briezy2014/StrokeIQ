import 'package:flutter/material.dart';

import '../shared/placeholder_body.dart';

class MeetsScreen extends StatelessWidget {
  const MeetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      icon: Icons.emoji_events,
      title: 'Meet Results',
      message: 'Track meet names, events, and result times.',
    );
  }
}
