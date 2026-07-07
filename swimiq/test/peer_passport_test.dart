import 'package:flutter_test/flutter_test.dart';
import 'package:swimiq/core/utils/social_link_utils.dart';
import 'package:swimiq/data/models/swimmer_profile.dart';

void main() {
  group('SwimmerProfile peer & social fields', () {
    test('stores social links and public flag in athlete notes', () {
      final notes = SwimmerProfile.composeAthleteNotes(
        instagram: '@aspenbreeze',
        tiktok: 'aspenbreeze',
        facebook: 'AspynWilliamsSwim',
        website: 'aspenbreeze.com',
        publicPassport: true,
        interestSports: const ['Volleyball'],
        interestAcademics: const ['NHS', 'STEM club'],
        interestPassions: const ['Photography'],
        beyondBio: 'I love service projects and art.',
      );

      final profile = SwimmerProfile(
        swimmerName: 'Aspyn Williams',
        firstName: 'Aspyn',
        lastName: 'Williams',
        athleteNotes: notes,
      );

      expect(profile.publicPassportEnabled, isTrue);
      expect(profile.personalWebsite, 'aspenbreeze.com');
      expect(profile.interestSports, ['Volleyball']);
      expect(profile.interestAcademics, contains('NHS'));
      expect(profile.beyondBio, contains('service projects'));
    });

    test('matches directory search by full name', () {
      final profile = SwimmerProfile(
        swimmerName: 'aspyn_williams',
        firstName: 'Aspyn',
        lastName: 'Williams',
        preferredName: 'Aspyn',
        athleteNotes: SwimmerProfile.composeAthleteNotes(publicPassport: true),
      );

      expect(profile.matchesDirectoryQuery('Aspyn Williams'), isTrue);
      expect(profile.matchesDirectoryQuery('williams'), isTrue);
      expect(profile.publicPassportEnabled, isTrue);
    });
  });

  group('SocialLinkUtils', () {
    test('builds website and instagram URLs', () {
      expect(
        SocialLinkUtils.websiteUrl('aspenbreeze.com'),
        'https://aspenbreeze.com',
      );
      expect(
        SocialLinkUtils.instagramUrl('@aspenbreeze'),
        'https://instagram.com/aspenbreeze',
      );
    });
  });
}
