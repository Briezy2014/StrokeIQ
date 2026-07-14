import 'app_constants.dart';

/// Legal document metadata — SwimIQ LLC is the operator; parent consent rules
/// for under-13 athletes are in Privacy Policy and Terms (see docs/legal/README.md).
abstract final class LegalConstants {
  static const appName = 'SwimIQ';
  static const operatorName = 'SwimIQ LLC';
  static const legalRepresentativeName = 'Kara Williams';
  static const productName = 'SwimIQ';
  static const founderName = 'Aspyn Briez Williams';
  static const companyName = operatorName;
  static const contactEmail = 'privacy@swimiqapp.com';
  static const supportEmail = 'support@swimiqapp.com';
  static const websiteUrl = 'https://swimiqapp.com';
  static const governingLawState = 'Ohio';
  static const mailingAddressLine1 = '199 Harbinger Dr.';
  static const mailingCityStateZip = 'Groveport, OH 43125';
  static const mailingCountry = 'United States';
  static const lastUpdated = 'July 14, 2026';

  static const privacyPolicyWebUrl = '$websiteUrl/privacy';
  static const termsOfServiceWebUrl = '$websiteUrl/terms';
  static const aiDisclosureWebUrl = '$websiteUrl/ai';

  /// Athlete age range SwimIQ is designed for (see Terms and Privacy Policy).
  static const athleteAgeMin = 8;
  static const athleteAgeMax = 30;
  static const athleteAgeRangeLabel = 'ages 8 through 30';

  static const privacyPolicyAsset = 'assets/legal/privacy_policy.txt';
  static const termsOfServiceAsset = 'assets/legal/terms_of_service.txt';
  static const aiDisclosureAsset = 'assets/legal/ai_data_disclosure.txt';

  static const aiConsentStorageKey = 'swimiq_ai_data_consent_v1';

  /// Full footer on Settings and legal document screens.
  static const settingsFooter =
      '${AppConstants.copyright} · SwimIQ provides coaching estimates only — not '
      'official meet timing or medical advice. Confirm with your coach. '
      '$operatorName · $mailingCityStateZip';

  /// Consent dialogs — company name only, no street address or personal name.
  static const compactFooter =
      '${AppConstants.copyright} · SwimIQ provides coaching estimates only — not '
      'official meet timing or medical advice. Confirm with your coach. '
      '$operatorName.';
}

enum LegalDocumentType {
  privacyPolicy(
    title: 'Privacy Policy',
    assetPath: LegalConstants.privacyPolicyAsset,
  ),
  termsOfService(
    title: 'Terms of Service',
    assetPath: LegalConstants.termsOfServiceAsset,
  ),
  aiDataDisclosure(
    title: 'AI & Data Disclosure',
    assetPath: LegalConstants.aiDisclosureAsset,
  );

  const LegalDocumentType({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;
}
