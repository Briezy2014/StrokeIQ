import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/services/usa_motivational_standards_catalog.dart';

late UsaMotivationalStandardsCatalog testMotivationalCatalog;

Future<void> loadTestMotivationalCatalog() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  testMotivationalCatalog =
      await UsaMotivationalStandardsCatalog.loadFromAssets();
}
