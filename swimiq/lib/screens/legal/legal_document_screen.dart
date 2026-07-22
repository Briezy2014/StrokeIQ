import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../core/constants/legal_constants.dart';
import '../../widgets/swimiq_header.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
  });

  final LegalDocumentType document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SwimIqScreenAppBarTitle(document.title),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(document.assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Could not load this document.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SelectableText(
                snapshot.data!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              const SwimIqCopyrightLine(),
              const SizedBox(height: 8),
              Text(
                LegalConstants.settingsFooter,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
