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

  /// Max swim clip size for Gemini File API analysis (matches edge function cap).
  static const maxGeminiVideoBytes = 50 * 1024 * 1024;

  /// Closed testing / demos: keep true so no paywall ads, tab locks, or Elite
  /// upgrade banners appear. Set false only when public paid launch is ready.
  static const unlockAllTabsForPreview = true;

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
