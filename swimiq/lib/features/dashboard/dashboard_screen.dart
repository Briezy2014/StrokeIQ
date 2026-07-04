import 'package:flutter/material.dart';

import '../shared/placeholder_body.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      icon: Icons.dashboard,
      title: 'Dashboard',
      message:
          'SwimIQ Score, metrics, and time-progress charts will appear here in the next milestone.',
    );
  }
}
