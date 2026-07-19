import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../core/constants/feature_flags.dart';
import '../providers/app_providers.dart';

/// Google Sign-In preparation for Supabase Auth.
///
/// Email/password auth is unchanged. This service is wired and ready, but
/// [FeatureFlags.googleSignInEnabled] stays false until OAuth clients and the
/// Supabase Google provider are configured. Do not call from login UI yet.
class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;

  /// Whether the feature flag and client IDs allow Google Sign-In.
  bool get isReadyToEnable {
    if (!FeatureFlags.googleSignInEnabled) return false;
    final webClientId = Env.googleWebClientId;
    return webClientId != null && webClientId.isNotEmpty;
  }

  /// Signs in with Google via ID token → Supabase.
  ///
  /// Throws [StateError] while the feature is disabled so accidental UI hooks
  /// cannot change production auth behavior.
  Future<AuthResponse> signInWithGoogle() async {
    if (!FeatureFlags.googleSignInEnabled) {
      throw StateError(
        'Google Sign-In is prepared but not enabled. '
        'Set FeatureFlags.googleSignInEnabled after configuring OAuth.',
      );
    }

    final webClientId = Env.googleWebClientId;
    if (webClientId == null || webClientId.isEmpty) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID is missing. Add it to .env / dart-define '
        'before enabling Google Sign-In.',
      );
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: const ['email', 'profile'],
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw AuthException('Google sign-in was canceled.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException('Google sign-in did not return an ID token.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  /// Web / fallback OAuth redirect flow (also gated by the feature flag).
  Future<bool> signInWithGoogleOAuth() async {
    if (!FeatureFlags.googleSignInEnabled) {
      throw StateError(
        'Google Sign-In is prepared but not enabled. '
        'Set FeatureFlags.googleSignInEnabled after configuring OAuth.',
      );
    }

    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.swimiq://login-callback/',
    );
  }

  Future<void> signOutGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e, st) {
      debugPrint('GoogleAuthService.signOutGoogle: $e\n$st');
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(ref.watch(supabaseClientProvider)),
);
