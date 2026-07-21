import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swimiq/config/env.dart';
import 'package:swimiq/config/supabase_config.dart';
import 'package:swimiq/core/constants/app_constants.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';
import 'package:swimiq/data/repositories/swimiq_repository.dart';

void main() {
  group('SwimmerProfile', () {
    test('normalizes empty stroke values from Supabase', () {
      final profile = SwimmerProfile.fromJson({
        'id': 4,
        'swimmer_name': 'Aspyn',
        'primary_stroke': '',
        'secondary_stroke': '',
      });

      expect(profile.primaryStroke, isNull);
      expect(profile.secondaryStroke, isNull);
    });

    test('round-trips recruiting profile fields in athlete notes', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          gpa: '3.92',
          athleteWebsite: 'https://aspyn-swims.example.com',
          otherInterests: 'Piano, NHS, water polo',
          imxScore: '2840',
          imrScore: '1950',
        ),
      );

      expect(profile.gpa, '3.92');
      expect(profile.athleteWebsite, 'https://aspyn-swims.example.com');
      expect(profile.otherInterests, 'Piano, NHS, water polo');
      expect(profile.imxScore, '2840');
      expect(profile.imrScore, '1950');
    });

    test('round-trips structured athlete notes metadata', () {
      final profile = SwimmerProfile(
        swimmerName: 'Aspyn',
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          gender: 'Female',
          height: '5\'4"',
          weight: '120 lbs',
          dominantHand: 'Right',
          trainingGroup: 'Senior',
          notes: 'Working on fly breakout.',
        ),
      );

      expect(profile.gender, 'Female');
      expect(profile.height, '5\'4"');
      expect(profile.weight, '120 lbs');
      expect(profile.dominantHand, 'Right');
      expect(profile.trainingGroup, 'Senior');
      expect(profile.notesBody, 'Working on fly breakout.');
    });
  });

  group('Athlete Passport dropdown values', () {
    String? dropdownStroke(String? value) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty) return null;
      return AppConstants.strokes.contains(normalized) ? normalized : null;
    }

    test('empty strings do not become invalid dropdown values', () {
      expect(dropdownStroke(''), isNull);
      expect(dropdownStroke(null), isNull);
      expect(dropdownStroke('Butterfly'), 'Butterfly');
      expect(dropdownStroke('Fly'), isNull);
    });
  });

  group('Athlete Passport Supabase persistence', () {
    test('loads and saves Aspyn profile', () async {
      if (!Env.isConfigured) return;
      final repository = SwimIqRepository(
        SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey),
      );
      final original = await repository.fetchProfile('Aspyn');
      expect(original, isNotNull);
      expect(original!.swimmerName, 'Aspyn');
      expect(original.team, 'COA');

      final marker = 'passport-test-${DateTime.now().millisecondsSinceEpoch}';
      const testCoach = 'Coach Test Name';
      final updated = original.copyWith(
        coachName: testCoach,
        athleteNotes: SwimmerProfile.composeAthleteNotes(
          trainingGroup: 'Senior',
          notes: marker,
        ),
      );

      try {
        final saved = await repository.saveProfile(updated);
        expect(saved.id, isNotNull);

        final reloaded = await repository.fetchProfile('Aspyn');
        expect(reloaded, isNotNull);
        expect(reloaded!.coachName, testCoach);
        expect(reloaded.trainingGroup, 'Senior');
        expect(reloaded.notesBody, marker);
      } finally {
        await repository.saveProfile(
          original.copyWith(
            coachName: 'Gunner Lehr',
            athleteNotes: original.athleteNotes ?? '',
          ),
        );
      }

      final restored = await repository.fetchProfile('Aspyn');
      expect(restored?.coachName, 'Gunner Lehr');
      expect(restored?.notesBody, original.notesBody);
      expect(restored?.trainingGroup, original.trainingGroup);
    });
  });
}
