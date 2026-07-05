import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'profile_service.dart';

/// Handles Supabase Auth for SwimIQ Version 1.
///
/// Each user is linked to one swimmer via `user_metadata.swimmer_name`
/// (no database schema change required).
class AuthService {
  AuthService(this._client, this._profileService);

  final SupabaseClient _client;
  final ProfileService _profileService;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String? get currentSwimmerName {
    final metadata = currentUser?.userMetadata;
    final name = metadata?['swimmer_name'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String swimmerName,
    String? firstName,
    String? lastName,
  }) async {
    final cleanName = swimmerName.trim();
    if (cleanName.isEmpty) {
      throw AuthException('Swimmer name is required.');
    }

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        AppConstants.swimmerNameMetadataKey: cleanName,
        if (firstName != null && firstName.trim().isNotEmpty)
          'first_name': firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty)
          'last_name': lastName.trim(),
      },
    );

    final user = response.user;
    if (user == null) {
      throw AuthException('Sign up failed. Please try again.');
    }

    await _profileService.ensureProfileExists(
      swimmerName: cleanName,
      firstName: firstName?.trim(),
      lastName: lastName?.trim(),
      preferredName: cleanName,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
