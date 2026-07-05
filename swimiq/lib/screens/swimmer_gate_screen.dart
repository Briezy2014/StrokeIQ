import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../widgets/swimiq_header.dart';

class SwimmerGateScreen extends ConsumerStatefulWidget {
  const SwimmerGateScreen({super.key});

  @override
  ConsumerState<SwimmerGateScreen> createState() => _SwimmerGateScreenState();
}

class _SwimmerGateScreenState extends ConsumerState<SwimmerGateScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSwimIq() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a swimmer name or code first.');
      return;
    }
    ref.read(activeSwimmerProvider.notifier).state = name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SwimIqHeader(),
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Welcome to SwimIQ Version 2 Beta. Built in the Water. '
                    'Driven by Possibility.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SwimIQ Version 2: Athlete Performance Edition',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter swimmer name or code',
                  hintText: 'Example: Emma12, JackFish, Aspyn',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _startSwimIq(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _startSwimIq,
                child: const Text('Start SwimIQ'),
              ),
              const SwimIqFooter(),
              const SizedBox(height: 8),
              Text(
                AppConstants.buildLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
