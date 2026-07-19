import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_providers.dart';

/// Email/password authentication via Supabase Auth.
///
/// Google Sign-In is prepared separately in `GoogleAuthService` and remains
/// disabled until `FeatureFlags.googleSignInEnabled` is turned on. Existing
/// email/password flows are unchanged.
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

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
