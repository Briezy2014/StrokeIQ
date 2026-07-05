import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Exposes authentication state to the widget tree.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;
  StreamSubscription<AuthState>? _subscription;

  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get currentUser => _authService.currentUser;

  String get displayName {
    final user = currentUser;
    if (user == null) return '';
    final metadataName = user.userMetadata?['display_name'] as String?;
    if (metadataName != null && metadataName.isNotEmpty) {
      return metadataName;
    }
    return user.email?.split('@').first ?? 'Swimmer';
  }

  Future<void> initialize() async {
    _subscription = _authService.authStateChanges.listen(_onAuthStateChanged);
    _setStatusFromSession(_authService.currentSession);
  }

  void _onAuthStateChanged(AuthState state) {
    _setStatusFromSession(state.session);
  }

  void _setStatusFromSession(Session? session) {
    final next = session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;

    if (_status != next) {
      _status = next;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    await _authService.signIn(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _errorMessage = null;
    return _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> signOut() async {
    _errorMessage = null;
    await _authService.signOut();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
