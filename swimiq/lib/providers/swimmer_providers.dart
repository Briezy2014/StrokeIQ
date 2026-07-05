import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/swimmer_repository.dart';

/// Resolves the active swimmer key from the authenticated Supabase user.
///
/// Uses [User.id] as the value stored in existing `swimmer` / `swimmer_name`
/// columns — no schema migration required.
final activeSwimmerKeyProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

/// Ensures a minimal swimmer profile exists for the signed-in user.
final swimmerBootstrapProvider = FutureProvider<void>((ref) async {
  final swimmerKey = ref.watch(activeSwimmerKeyProvider);
  if (swimmerKey == null) return;

  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  await ref.read(swimmerRepositoryProvider).ensureProfile(
        swimmerKey: swimmerKey,
        email: user.email,
      );
});
