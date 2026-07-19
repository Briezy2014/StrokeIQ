/// Compile-time feature switches for UX that is built but not yet enabled.
///
/// Flip these to `true` in a later release once product/config is ready.
/// No additional structural changes should be required.
class FeatureFlags {
  FeatureFlags._();

  /// When true, first-launch users see the onboarding walkthrough until they
  /// complete or skip it. Settings can always reopen the walkthrough.
  static const bool onboardingEnabled = false;

  /// When true, Google Sign-In is offered alongside email/password.
  /// Keep false until Supabase Google provider + OAuth client IDs are configured.
  static const bool googleSignInEnabled = false;
}
