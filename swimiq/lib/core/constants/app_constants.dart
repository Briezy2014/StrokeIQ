class AppConstants {
  static const appName = 'SwimIQ';
  static const trademark = 'SwimIQ™';
  /// Primary brand asset — square PNG lockup (512×512). Login/signup read this file.
  static const brandIconAsset = 'assets/branding/icon.png';
  /// Mirror of [brandIconAsset] for brand-kit folder naming (`logo.png`).
  static const brandLogoAsset = 'assets/branding/logo.png';
  static const brandIconSizePx = 512;
  static const tagline = '';
  static const brandTagline = 'Built in the Water. Driven by Possibility.';
  static const brandTaglineShort = 'Performance. Precision. Possibility.';
  static const founder = '';
  static const copyright = '© 2026 SwimIQ LLC';

  /// Max swim clip size for Gemini analysis — must match Edge Function
  /// `MAX_FILE_API_BYTES` (100 MB). Typical phone race clips fit; trim or
  /// re-export only when the file is larger than this ceiling.
  static const maxGeminiVideoBytes = 100 * 1024 * 1024;
  static const maxGeminiVideoMb = 100;

  /// When true, all plan gates are open (dev only). Keep false in production so
  /// Basic / Pro / Elite users only see features included in their plan.
  /// Demo and master emails still receive Elite via SubscriptionService.
  static const unlockAllTabsForPreview = false;

  /// Official 2024-2028 USA Swimming age-group brackets from the motivational PDF.
  static const ageGroups = [
    '10 & under',
    '11-12',
    '13-14',
    '15-16',
    '17-18',
  ];

  static const genders = ['Girls', 'Boys'];

  static const strokes = [
    'Freestyle',
    'Backstroke',
    'Breaststroke',
    'Butterfly',
    'IM',
  ];

  static const courses = ['SCY', 'SCM', 'LCM'];
}
