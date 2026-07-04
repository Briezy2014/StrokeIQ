import 'package:flutter/material.dart';

import '../shared/placeholder_body.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      icon: Icons.flag,
      title: 'Goals',
      message: 'Set target times and dates for your events.',
    );
  }
}
