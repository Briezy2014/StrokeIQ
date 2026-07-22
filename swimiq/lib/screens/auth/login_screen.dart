import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/owner_account_constants.dart';
import '../../core/models/subscription_plan.dart';
import '../../core/services/pending_coach_code_storage.dart';
import '../../core/utils/auth_validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_gradient_background.dart';
import '../../widgets/coach_access_code_dialog.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/swimiq_header.dart';
import '../../widgets/swimiq_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.onSwitchToSignup});

  final VoidCallback onSwitchToSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthException catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _coachAccess() async {
    final code = await showCoachAccessCodeDialog(context);
    if (code == null || !mounted) return;

    await PendingCoachCodeStorage.save(code);
    if (!mounted) return;

    final createAccount = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coach preview unlocked'),
        content: Text(
          'Your code is saved. Create your coach account below, or sign in if you '
          'already have one — you will get ${SubscriptionCatalog.coachTrialDays}-day Pro '
          'access plus ${SubscriptionCatalog.coachElitePeekDays} days of Elite AI '
          '(${SubscriptionCatalog.coachEliteAnalysisLimit} video analyses).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sign in below'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create account'),
          ),
        ],
      ),
    );

    if (!mounted || createAccount != true) return;
    widget.onSwitchToSignup();
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || AuthValidators.email(email) != null) {
      setState(
        () => _errorMessage = 'Enter your account email above, then tap '
            'Forgot password.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link is on the way. '
            'Check your inbox.',
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ownerLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: OwnerAccountConstants.email,
            password: OwnerAccountConstants.password,
          );
    } on AuthException catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } catch (e) {
      setState(() => _errorMessage = AuthErrorMapper.fromException(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: SwimIqLoginBrand()),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage != null) ...[
                              _ErrorBanner(message: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: AuthValidators.password,
                            ),
                            const SizedBox(height: 24),
                            LoadingButton(
                              label: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _forgotPassword,
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onSwitchToSignup,
                              child: const Text('Create an account'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _coachAccess,
                              icon: const Icon(Icons.school_outlined, size: 18),
                              label: const Text('Coach access'),
                            ),
                            if (!kReleaseMode) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _isLoading ? null : _ownerLogin,
                                child: const Text(
                                  'Owner test login (Elite AI)',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SwimIqCopyrightLine(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}
