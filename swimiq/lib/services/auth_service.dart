import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_providers.dart';

/// Email/password authentication via Supabase Auth.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null && displayName.trim().isNotEmpty
          ? {'display_name': displayName.trim()}
          : null,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Clears local session without requiring network (recover from refresh failures).
  Future<void> signOutLocal() =>
      _client.auth.signOut(scope: SignOutScope.local);

  /// Sends a password-reset email via Supabase Auth.
  Future<void> resetPassword({required String email}) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Best-effort token refresh after a transient network failure.
  Future<bool> tryRefreshSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return false;
    try {
      await _client.auth.refreshSession();
      return _client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// Maps an authenticated user to the swimmer key used in race_logs.
  static String swimmerKeyForUser(User user) {
    final displayName = user.userMetadata?['display_name'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return user.id;
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

/// Auth stream that never permanently bricks the app on refresh/network errors.
///
/// Supabase emits [AuthRetryableFetchException] on the auth stream when a
/// refresh_token request fails to fetch (offline, DNS, transient outage).
/// A raw [StreamProvider] would stay in [AsyncError] forever — showing
/// "SwimIQ is not connected yet". We keep the stream alive and fall back to
/// the current session or a clean signed-out state so Login remains reachable.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<AuthState>();

  void seed() {
    try {
      controller.add(
        AuthState(AuthChangeEvent.initialSession, client.auth.currentSession),
      );
    } catch (_) {
      controller.add(const AuthState(AuthChangeEvent.initialSession, null));
    }
  }

  seed();

  final sub = client.auth.onAuthStateChange.listen(
    (state) {
      if (!controller.isClosed) controller.add(state);
    },
    onError: (Object error, StackTrace stack) {
      if (controller.isClosed) return;
      final session = client.auth.currentSession;
      final stillUsable = session != null && !session.isExpired;
      if (stillUsable) {
        // Transient refresh failure — keep the usable session.
        controller.add(AuthState(AuthChangeEvent.tokenRefreshed, session));
        return;
      }
      // Expired / missing session after a failed refresh — clear local junk so
      // the next login is clean, then surface signed-out.
      unawaited(() async {
        try {
          await client.auth.signOut(scope: SignOutScope.local);
        } catch (_) {}
      }());
      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    },
    onDone: () {
      if (!controller.isClosed) controller.close();
    },
    cancelOnError: false,
  );

  ref.onDispose(() {
    unawaited(sub.cancel());
    if (!controller.isClosed) controller.close();
  });

  return controller.stream;
});

final currentUserProvider = Provider<User?>((ref) {
  // Widget tests and early boot may render before Supabase.initialize().
  // Avoid touching Supabase.instance.client until it is ready.
  if (!Supabase.instance.isInitialized) return null;
  return ref.watch(authStateProvider).value?.session?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
