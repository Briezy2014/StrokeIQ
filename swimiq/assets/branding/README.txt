SwimIQ branding folder
========================

Use ONE logo file for the entire app and website build:

  swimiq_logo.png

Put your official SWIMIQ artwork here:
  swimiq/assets/branding/swimiq_logo.png

That same file is used everywhere — splash, login, app bar, passport,
headers, and the GoDaddy web build. You do NOT need separate hero or
icon PNG files.

After adding or replacing the file:
  flutter clean
  flutter pub get
  flutter run -d chrome

To update swimiqapp.com, rebuild with scripts\build-web-godaddy.ps1
and upload build\web to GoDaddy public_html.
