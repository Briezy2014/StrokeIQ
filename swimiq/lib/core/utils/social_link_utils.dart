/// Normalizes social handles and personal sites into tappable URLs.
abstract final class SocialLinkUtils {
  static String? normalizeUrl(String? raw, {String? defaultHost}) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    if (text.contains('://')) {
      return text.startsWith('http') ? text : 'https://$text';
    }

    if (defaultHost != null) {
      final handle = text.startsWith('@') ? text.substring(1) : text;
      if (handle.isEmpty) return null;
      return 'https://$defaultHost/$handle';
    }

    return 'https://$text';
  }

  static String? instagramUrl(String? raw) =>
      normalizeUrl(raw, defaultHost: 'instagram.com');

  static String? tiktokUrl(String? raw) =>
      normalizeUrl(raw, defaultHost: 'tiktok.com/@');

  static String? facebookUrl(String? raw) =>
      normalizeUrl(raw, defaultHost: 'facebook.com');

  static String? websiteUrl(String? raw) => normalizeUrl(raw);

  static String displayHandle(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return '';
    if (text.contains('instagram.com')) return '@${text.split('/').last}';
    if (text.contains('tiktok.com')) return '@${text.split('/').last}';
    return text;
  }
}
