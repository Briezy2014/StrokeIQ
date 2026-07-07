/// Legal document metadata — update [operatorName] if you form an LLC or use a DBA.
abstract final class LegalConstants {
  static const appName = 'SwimIQ';
  static const operatorName = 'SwimIQ';
  static const companyName = operatorName;
  static const contactEmail = 'privacy@swimiq.app';
  static const supportEmail = 'support@swimiq.app';
  static const websiteUrl = 'https://swimiq.app';
  static const governingLawState = 'Ohio';
  static const mailingAddressLine1 = '199 Harbinger Dr.';
  static const mailingCityStateZip = 'Groveport, OH 43125';
  static const mailingCountry = 'United States';
  static const lastUpdated = 'July 7, 2026';

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

  static const settingsFooter =
      'SwimIQ provides coaching estimates only — not official meet timing or '
      'medical advice. Confirm with your coach. © $lastUpdated $operatorName.';
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
