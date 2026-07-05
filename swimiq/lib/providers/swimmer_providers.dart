import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';

/// Resolves the active swimmer key from the authenticated Supabase user.
///
/// Uses [User.id] as the value stored in the existing `swimmer` column on
/// data tables — no schema migration required.
final activeSwimmerKeyProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});
