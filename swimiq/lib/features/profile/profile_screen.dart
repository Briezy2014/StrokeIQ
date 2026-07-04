import 'package:flutter/material.dart';

import '../shared/placeholder_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      icon: Icons.person,
      title: 'Athlete Passport',
      message: 'View and edit your swimmer profile.',
    );
  }
}
