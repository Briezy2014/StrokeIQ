# Android release build (Google Play)

Use this when uploading SwimIQ to Google Play. **Web** builds are unchanged (`scripts/build-web-godaddy.ps1`).

---

## One-time: create upload keystore

**Easiest:** double-click **`CREATE-KEYSTORE.bat`** in the `swimiq` folder (finds `keytool` from Android Studio automatically).

Or in PowerShell:

```powershell
cd S:\swimiq
powershell -ExecutionPolicy Bypass -File scripts\create-android-keystore.ps1
```

If you see **`keytool is not recognized`**, Android Studio’s Java is not on PATH. Use the full path:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\keystores\swimiq-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias swimiq
```

**No Android Studio?** Install it first: https://developer.android.com/studio — then run `CREATE-KEYSTORE.bat` again.

Use real values when prompted (name: Kara Williams, org: SwimIQ, city: Groveport, state: OH). **Write down the password.**

Copy the example config and fill in your passwords:

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

The script reads Supabase values from `.env` if present, or pass them explicitly:

```powershell
.\scripts\build-android-release.ps1 `
  -SupabaseUrl "https://YOUR_PROJECT.supabase.co" `
  -SupabaseAnonKey "YOUR_ANON_KEY"
```

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

1. Play Console → your app → **Release** → **Production** (or **Internal testing** first)
2. **Create new release** → upload `app-release.aab`
3. Enable **Google Play App Signing** when prompted (recommended)
4. Bump `version` in `pubspec.yaml` before each new upload (`1.0.0+1` → `1.0.0+2`, etc.)

---

## Signing behavior

| `android/key.properties` | Release build uses |
|--------------------------|-------------------|
| Present | Your upload keystore (`swimiq-upload-keystore.jks`) |
| Missing | Debug keystore (local testing only — **not** for Play upload) |

---

## Subscriptions at launch

Android v1 ships with **Elite trial + coach preview codes only**. Paid upgrades use **Google Play Billing** in a later release. Stripe checkout remains on **swimiqapp.com** (web). The app blocks paid plan selection on Android/iOS to stay Play-policy compliant.

See `lib/core/subscription/subscription_billing_policy.dart`.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `key.properties` not found | Copy from `key.properties.example` |
| Wrong Supabase at runtime | Pass `--dart-define` values; `.env` is not bundled in release |
| Windows path with spaces | Use `S:\swimiq` — see `docs/WINDOWS_SETUP.md` |
| Upload rejected (debug signed) | Create keystore + `key.properties`, rebuild |

---

**Package name:** `com.swimiq.swimiq`  
**Support:** support@swimiqapp.com
