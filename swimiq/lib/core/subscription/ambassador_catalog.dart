/// Named SwimIQ ambassadors — unique preview codes + share links.
///
/// Commission tracking (30%) is handled by Rewardful once connected to Stripe.
/// These first-party codes unlock coach preview access and identify who shared.
class SwimIqAmbassador {
  const SwimIqAmbassador({
    required this.name,
    required this.code,
    required this.slug,
  });

  final String name;

  /// Preview unlock code (Settings → Plans, or `?amb=`).
  final String code;

  /// Rewardful-friendly token (`?via=slug`). Keep lowercase.
  final String slug;

  String get shareUrl => 'https://swimiqapp.com/?amb=$code';

  /// Link format Rewardful uses after you create the affiliate.
  String get viaUrl => 'https://swimiqapp.com/?via=$slug';

  /// Combined link: preview unlock + Rewardful-ready via token.
  String get preferredShareUrl =>
      'https://swimiqapp.com/?amb=$code&via=$slug';
}

abstract final class AmbassadorCatalog {
  AmbassadorCatalog._();

  /// Generic shared code (team-wide, not attributable to one person).
  static const shared = SwimIqAmbassador(
    name: 'SwimIQ shared',
    code: 'AMBASSADOR-SWIMIQ',
    slug: 'swimiq',
  );

  static const ruslan = SwimIqAmbassador(
    name: 'Ruslan',
    code: 'AMB-RUSLAN',
    slug: 'ruslan',
  );

  static const nyah = SwimIqAmbassador(
    name: 'Nyah',
    code: 'AMB-NYAH',
    slug: 'nyah',
  );

  static const List<SwimIqAmbassador> named = [ruslan, nyah];

  static const List<SwimIqAmbassador> all = [shared, ruslan, nyah];

  static SwimIqAmbassador? byCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    for (final ambassador in all) {
      if (ambassador.code == normalized) return ambassador;
    }
    return null;
  }

  static SwimIqAmbassador? bySlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) return null;
    final normalized = slug.trim().toLowerCase();
    for (final ambassador in all) {
      if (ambassador.slug == normalized) return ambassador;
    }
    return null;
  }

  static bool isAmbassadorAccessCode(String code) => byCode(code) != null;

  /// Resolves `amb` / `ref` / `code` / `via` into a preview unlock code.
  static String? promoCodeFromUri(Uri uri) {
    final via = bySlug(uri.queryParameters['via']);
    if (via != null) return via.code;

    final raw = uri.queryParameters['amb'] ??
        uri.queryParameters['ref'] ??
        uri.queryParameters['code'];
    final byAccessCode = byCode(raw);
    if (byAccessCode != null) return byAccessCode.code;
    return null;
  }

  /// Rewardful / Stripe attribution slug from the landing URL.
  static String? referralSlugFromUri(Uri uri) {
    final via = bySlug(uri.queryParameters['via']);
    if (via != null) return via.slug;
    final amb = byCode(
      uri.queryParameters['amb'] ??
          uri.queryParameters['ref'] ??
          uri.queryParameters['code'],
    );
    return amb?.slug;
  }
}
