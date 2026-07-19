import 'package:share_plus/share_plus.dart';

import '../constants/store_constants.dart';

/// Shares SwimIQ via the platform share sheet (Messages, Gmail, social, etc.).
class AppShareService {
  AppShareService._();

  static Future<void> shareSwimIq() {
    return Share.share(
      StoreConstants.shareMessage,
      subject: 'SwimIQ — swim smarter',
    );
  }
}
