import 'package:flutter/material.dart';

/// Meet results placeholder.
class MeetResultsScreen extends StatelessWidget {
  const MeetResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet Results'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Meet results from the meet_results table will appear here. '
            'Add and view meet times in the next milestone.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
