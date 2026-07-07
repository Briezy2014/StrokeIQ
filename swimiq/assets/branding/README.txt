SwimIQ branding folder
========================

Drop your two logo files here, then run branding icon setup:

  powershell -ExecutionPolicy Bypass -File scripts\apply-branding-icons.ps1
  flutter clean
  flutter run -d chrome

Required files (use these exact names):
  swimiq_icon.png  — square SWIMIQ icon (app bar, passport circle)
  swimiq_hero.png  — wide banner with tagline (welcome / login screen)

Alternate names also work:
  icon.png, logo_icon.png  → square icon
  hero.png, banner.png     → wide banner

After adding or renaming files, always run flutter clean before flutter run.
