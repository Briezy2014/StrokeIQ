import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Supported authentication methods. OAuth providers are reserved for later milestones.
enum AuthProviderType {
  emailPassword,
  google,
  apple,
}

/// Authentication contract designed for email/password now and OAuth later.
abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;

  User? get currentUser;

  Session? get currentSession;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithProvider(AuthProviderType provider);

  Future<void> signOut();

  Future<void> resetPassword(String email);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithProvider(AuthProviderType provider) {
    switch (provider) {
      case AuthProviderType.google:
        throw UnimplementedError(
          'Google Sign-In will be added in a future milestone.',
        );
      case AuthProviderType.apple:
        throw UnimplementedError(
          'Apple Sign-In will be added in a future milestone.',
        );
      case AuthProviderType.emailPassword:
        throw ArgumentError(
          'Use signInWithEmail for email/password authentication.',
        );
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
