import 'package:flutter/material.dart';

import '../shared/placeholder_body.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      icon: Icons.fitness_center,
      title: 'Training Log',
      message: 'Add and review swim sessions from your race logs.',
    );
  }
}
