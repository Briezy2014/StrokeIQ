/// Founder accounts always receive full Elite access (Pro + AI) for QA and family use.
abstract final class FounderAccountConstants {
  static const briezyEmail = 'briezy682014@gmail.com';

  static const emails = {
    briezyEmail,
    'owner@swimiqapp.com',
  };

  static bool isFounderEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return emails.contains(email.trim().toLowerCase());
  }

  /// Coach preview codes are admin-only — visible on Membership for Briezy login.
  static bool canViewCoachAdminCodes(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return email.trim().toLowerCase() == briezyEmail;
  }
}
