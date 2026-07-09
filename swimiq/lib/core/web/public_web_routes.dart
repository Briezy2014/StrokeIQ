import 'package:flutter/foundation.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/legal_constants.dart';
import '../../screens/legal/legal_document_screen.dart';
import '../../screens/legal/public_delete_account_screen.dart';

/// Public swimiqapp.com pages that must not require login (Play Console, legal links).
enum PublicWebRoute {
  deleteAccount,
  privacy,
  terms,
  ai;

  static PublicWebRoute? fromUri(Uri uri) {
    final pageParam = uri.queryParameters['page']?.toLowerCase();
    if (pageParam != null) {
      return switch (pageParam) {
        'delete-account' || 'delete' || 'data-deletion' => PublicWebRoute.deleteAccount,
        'privacy' => PublicWebRoute.privacy,
        'terms' => PublicWebRoute.terms,
        'ai' => PublicWebRoute.ai,
        _ => null,
      };
    }

    final path = uri.path.toLowerCase();
    if (path.contains('delete-account') || path.contains('data-deletion')) {
      return PublicWebRoute.deleteAccount;
    }
    if (path == '/privacy' || path.endsWith('/privacy.html')) {
      return PublicWebRoute.privacy;
    }
    if (path == '/terms' || path.endsWith('/terms.html')) {
      return PublicWebRoute.terms;
    }
    if (path == '/ai' || path.endsWith('/ai.html')) {
      return PublicWebRoute.ai;
    }
    return null;
  }

  String get playConsoleDeletionUrl {
    return switch (this) {
      PublicWebRoute.deleteAccount => LegalConstants.dataDeletionWebUrl,
      PublicWebRoute.privacy => '${LegalConstants.privacyPolicyWebUrl}#delete-account',
      _ => LegalConstants.dataDeletionWebUrl,
    };
  }
}

/// Root widget for a public legal page (no auth).
class PublicWebRouteScreen extends StatelessWidget {
  const PublicWebRouteScreen({super.key, required this.route});

  final PublicWebRoute route;

  @override
  Widget build(BuildContext context) {
    return switch (route) {
      PublicWebRoute.deleteAccount => const PublicDeleteAccountScreen(),
      PublicWebRoute.privacy => const LegalDocumentScreen(
          document: LegalDocumentType.privacyPolicy,
        ),
      PublicWebRoute.terms => const LegalDocumentScreen(
          document: LegalDocumentType.termsOfService,
        ),
      PublicWebRoute.ai => const LegalDocumentScreen(
          document: LegalDocumentType.aiDataDisclosure,
        ),
    };
  }
}
