import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Email/password authentication via Supabase Auth.
class AuthService {
  AuthService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? SupabaseService.client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

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
}
