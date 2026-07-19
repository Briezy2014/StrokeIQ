import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/onboarding_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/swimiq_logo.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// Swipeable first-launch walkthrough (disabled until FeatureFlags.onboardingEnabled).
///
/// Can also be opened from Settings at any time via [openedFromSettings].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.openedFromSettings = false,
    this.onFinished,
  });

  /// When true, Skip / Get Started pops the route instead of relying on app root.
  final bool openedFromSettings;

  /// Called after completion is stored (first-launch root flow).
  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      title: 'Welcome to SwimIQ',
      body: 'Your AI-powered swimming performance platform.',
      icon: Icons.waves_rounded,
    ),
    _OnboardingPage(
      title: 'Track Your Progress',
      body: 'Track goals, personal bests, and swim progress.',
      icon: Icons.flag_rounded,
    ),
    _OnboardingPage(
      title: 'Analyze With AI',
      body: 'Analyze races and improve your technique with AI-powered tools.',
      icon: Icons.analytics_outlined,
    ),
    _OnboardingPage(
      title: 'Stay Motivated',
      body: 'Stay motivated with achievements, insights, and performance tracking.',
      icon: Icons.emoji_events_outlined,
    ),
    _OnboardingPage(
      title: "Let's Swim Smarter.",
      body: 'You are ready to train with clarity and purpose.',
      icon: Icons.pool,
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index >= _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await OnboardingStorage.markCompleted();
    if (!mounted) return;
    if (widget.openedFromSettings) {
      Navigator.of(context).pop();
      return;
    }
    widget.onFinished?.call();
  }

  void _next() {
    if (_isLast) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceLight,
              Colors.white,
              Color(0xFFF0F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    const SwimIqLogo(size: 40, borderRadius: 10),
                    const SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLast)
                      TextButton(
                        onPressed: _complete,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _OnboardingPageView(page: page);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final selected = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: selected ? 22 : 8,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.28),
                ],
              ),
            ),
            child: Icon(page.icon, size: 52, color: AppColors.primaryDeep),
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textDark.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
