import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/app_providers.dart';

class SwimmerLoginScreen extends ConsumerStatefulWidget {
  const SwimmerLoginScreen({super.key});

  @override
  ConsumerState<SwimmerLoginScreen> createState() => _SwimmerLoginScreenState();
}

class _SwimmerLoginScreenState extends ConsumerState<SwimmerLoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a swimmer name or code first.')),
      );
      return;
    }

    setState(() => _loading = true);
    await ref.read(activeSwimmerProvider.notifier).setSwimmer(name);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: SwimIQTheme.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SwimIQTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.pool_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'SwimIQ',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: SwimIQTheme.deepBlue,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built in the Water. Driven by Possibility.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SwimIQTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Founded by Aspyn Briez',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SwimIQTheme.softBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SwimIQTheme.borderBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to SwimIQ Version 1',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SwimIQTheme.darkNavy,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Athlete Performance Edition — track sessions, goals, and meet results.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _start(),
                decoration: const InputDecoration(
                  labelText: 'Swimmer name or code',
                  hintText: 'Example: Emma12, JackFish, Aspyn',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _start,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Start SwimIQ'),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 SwimIQ · Founded by Aspyn Briez',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
