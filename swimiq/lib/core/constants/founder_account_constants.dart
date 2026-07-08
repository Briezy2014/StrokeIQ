/// Founder accounts always receive full Elite access (Pro + AI) for QA and family use.
abstract final class FounderAccountConstants {
  static const emails = {
    'briezy682014@gmail.com',
    'owner@swimiqapp.com',
  };

  static bool isFounderEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return emails.contains(email.trim().toLowerCase());
  }
}
