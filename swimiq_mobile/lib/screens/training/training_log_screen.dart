import 'package:flutter/material.dart';

import '../../widgets/swimiq_app_bar.dart';

/// Training log placeholder — list + add session form comes next.
class TrainingLogScreen extends StatelessWidget {
  const TrainingLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SwimIqAppBar(subtitle: 'Training Log'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Training sessions from the race_logs table will be listed here. '
            'You will be able to add new swims in the next milestone.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
