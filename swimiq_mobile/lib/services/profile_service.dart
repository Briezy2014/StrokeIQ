import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/swimmer_profile.dart';

/// Reads and creates swimmer profiles in the `swimmers` table.
class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  Future<SwimmerProfile?> getProfileBySwimmerName(String swimmerName) async {
    final response = await _client
        .from(AppConstants.swimmersTable)
        .select()
        .eq('swimmer_name', swimmerName)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return SwimmerProfile.fromJson(response);
  }

  /// Creates a swimmer profile if one does not already exist.
  Future<SwimmerProfile> ensureProfileExists({
    required String swimmerName,
    String? firstName,
    String? lastName,
    String? preferredName,
  }) async {
    final existing = await getProfileBySwimmerName(swimmerName);
    if (existing != null) {
      return existing;
    }

    final profile = SwimmerProfile(
      swimmerName: swimmerName,
      firstName: firstName,
      lastName: lastName,
      preferredName: preferredName ?? swimmerName,
    );

    final inserted = await _client
        .from(AppConstants.swimmersTable)
        .insert(profile.toInsertJson())
        .select()
        .single();

    return SwimmerProfile.fromJson(inserted);
  }
}
