import 'package:flutter/material.dart';

import '../../widgets/swimiq_app_bar.dart';

/// Goals placeholder.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Goals'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your swimmer goals will be listed here. '
            'Add and track target times in the next milestone.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
