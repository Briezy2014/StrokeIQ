# SwimIQ Brand Assets

Official logo files used throughout the Flutter app.

| File | Use |
|---|---|
| `swimiq_app_icon.png` | App launcher icon (Android/iOS), small avatars |
| `swimiq_logo.png` | Icon + SWIMIQ wordmark (auth screens, app bar) |
| `swimiq_branding_full.png` | Full splash branding with signature + tagline |
| `swimiq_icon_source.png` | Source crop of the graphic icon |

## Replacing assets

If you have updated logo files from design (e.g. app icon with blue rounded border), replace the matching PNG in this folder and run:

```bash
flutter pub get
flutter run
```

To regenerate launcher icons after replacing `swimiq_app_icon.png`, re-run the icon generation step in the project README or use `flutter_launcher_icons`.
