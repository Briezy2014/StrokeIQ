# Android release build (Google Play)

Use this when uploading SwimIQ to Google Play. **Web** builds stay on `scripts/build-web-godaddy.ps1`.

---

## One-time: create upload keystore

**Easiest:** double-click **`CREATE-KEYSTORE.bat`** in the `swimiq` folder.

Or:

```powershell
cd S:\swimiq
powershell -ExecutionPolicy Bypass -File scripts\create-android-keystore.ps1
```

If `keytool` is missing, use Android Studio’s copy:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\keystores\swimiq-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias swimiq
```

**Write down the password** and store the `.jks` offline (USB + password manager). Losing it means you cannot update the Play listing with the same signing key.

```powershell
copy android\key.properties.example android\key.properties
notepad android\key.properties
```

`android/key.properties` and `android/keystores/*.jks` are **gitignored**.

---

## Every release build

### Option A — script (recommended)

```powershell
cd S:\swimiq
.\scripts\build-android-release.ps1
```

Or double-click **`BUILD-ANDROID-NOW.bat`**.

Output: `build\app\outputs\bundle\release\app-release.aab`

### Option B — manual

```powershell
cd S:\swimiq
flutter pub get
flutter build appbundle --release `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## Play Console upload

1. Play Console → app → **Release** → **Internal testing** first (then Production)
2. Upload `app-release.aab`
3. Enable **Google Play App Signing** when prompted
4. Bump `version` in `pubspec.yaml` before each upload (`1.0.0+1` → `1.0.0+2`)

**Package name:** `com.swimiq.swimiq`

---

## Signing behavior

| `android/key.properties` | Release build uses |
|--------------------------|-------------------|
| Present | Upload keystore |
| Missing | Debug keystore — **Play will reject / unsafe for store** |

---

## Subscriptions at launch

Android v1 ships with **Elite trial + coach preview codes only**. Paid upgrades need **Google Play Billing** (later). Stripe stays on **web**. The app **blocks** paid plan selection on Android/iOS so Play review does not see free unlocks.

See `lib/core/subscription/subscription_billing_policy.dart`.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `key.properties` not found | Copy from `key.properties.example` |
| Wrong Supabase at runtime | Pass `--dart-define`; `.env` is not bundled in release |
| Upload rejected (debug signed) | Create keystore + `key.properties`, rebuild |
| Duplicate Gradle confusion | Use only `*.gradle.kts` (Groovy duplicates removed) |

---

**Support:** support@swimiqapp.com  
**Full checklist:** [ANDROID_LAUNCH_CHECKLIST.md](ANDROID_LAUNCH_CHECKLIST.md)
