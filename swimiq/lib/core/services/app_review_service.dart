import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/store_constants.dart';

/// Rates SwimIQ via Google Play In-App Review, with Play listing fallback.
class AppReviewService {
  AppReviewService._();

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Requests an in-app review when the Play API is available.
  ///
  /// Google provides no callback for whether the review dialog was shown and
  /// may silently suppress it. After attempting the in-app flow (or when it is
  /// unavailable / fails), this opens the SwimIQ Google Play listing so Rate
  /// SwimIQ always gives the user a path to leave a review.
  static Future<void> rateSwimIq() async {
    try {
      if (!kIsWeb) {
        final available = await _inAppReview.isAvailable();
        if (available) {
          await _inAppReview.requestReview();
        }
      }
    } catch (_) {
      // Continue to Play listing fallback.
    }

    await _openPlayListing();
  }

  static Future<void> _openPlayListing() async {
    try {
      if (!kIsWeb) {
        await _inAppReview.openStoreListing();
        return;
      }
    } catch (_) {
      // Fall through to URL launch.
    }

    final uri = Uri.parse(StoreConstants.playStoreUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}
