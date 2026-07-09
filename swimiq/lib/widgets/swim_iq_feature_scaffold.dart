import 'package:flutter/material.dart';

import 'swimiq_header.dart';

/// Scaffold wrapper for screens opened via [Navigator.push] (outside [HomeScreen]).
class SwimIqFeatureScaffold extends StatelessWidget {
  const SwimIqFeatureScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SwimIqScreenAppBarTitle(title),
      ),
      body: body,
    );
  }
}
