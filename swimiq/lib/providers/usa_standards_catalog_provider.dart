import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/usa_motivational_standards_catalog.dart';

class UsaMotivationalStandardsNotifier
    extends AsyncNotifier<UsaMotivationalStandardsCatalog> {
  @override
  Future<UsaMotivationalStandardsCatalog> build() async {
    return UsaMotivationalStandardsCatalog.loadFromAssets();
  }

  /// Replace the in-memory catalog from an uploaded USA Swimming JSON file.
  Future<String?> loadFromJsonString(String raw) async {
    try {
      final catalog = UsaMotivationalStandardsCatalog.parseJsonString(raw);
      state = AsyncData(catalog);
      return null;
    } catch (error) {
      return 'Could not load standards file: $error';
    }
  }
}

final usaMotivationalStandardsCatalogProvider = AsyncNotifierProvider<
    UsaMotivationalStandardsNotifier, UsaMotivationalStandardsCatalog>(
  UsaMotivationalStandardsNotifier.new,
);
