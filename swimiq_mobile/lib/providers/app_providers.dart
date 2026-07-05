import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/race_log_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

final raceLogServiceProvider = Provider<RaceLogService>((ref) {
  return RaceLogService(ref.watch(supabaseClientProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(supabaseClientProvider),
    ref.watch(profileServiceProvider),
  );
});

/// Notifies [GoRouter] when the Supabase auth session changes.
final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier(ref.watch(authServiceProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentSwimmerNameProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentSwimmerName;
});

final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser?.email;
});

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(this._authService) {
    _subscription = _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  final AuthService _authService;
  late final StreamSubscription<AuthState> _subscription;

  bool get isLoggedIn => _authService.currentSession != null;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
