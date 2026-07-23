# Google Play — SwimIQ Android (.aab)

Step-by-step for Kara's laptop. **Double-click `.bat` files** — do not paste long paths into PowerShell unless a step says so.

---

## Why builds fail (most common on your laptop)

| Symptom | Fix |
|--------|-----|
| `No Android SDK found` | Install **Android Studio** → SDK Manager → Android SDK + Build-Tools |
| `Android licenses not accepted` | Open terminal: `flutter doctor --android-licenses` → type `y` for all |
| Gradle / Kotlin version errors | **Pull latest** — we removed duplicate `build.gradle` files (only `.kts` now) |
| Gradle out of memory | Close Chrome, reboot, retry; we lowered Gradle RAM to 4GB |
| Play Console rejects upload | You need **`.aab`**, not `.apk`, signed with **your upload keystore** |
| `key.properties` missing | Run `GENERATE-ANDROID-KEYSTORE.bat` once |

---

## One-time setup

### 1. Android Studio + SDK
1. Install [Android Studio](https://developer.android.com/studio)
2. Open **SDK Manager** → install **Android SDK**, **SDK Platform**, **Build-Tools**
3. In a terminal (from `S:\swimiq`):

```bat
flutter doctor
flutter doctor --android-licenses
```

All items should show ✓ for Android toolchain.

### 2. Create upload keystore (once — save passwords forever)

1. Double-click **`GENERATE-ANDROID-KEYSTORE.bat`**
2. Choose a **store password** and **key password** (write them down)
3. Edit **`android\key.properties`** — replace `YOUR_STORE_PASSWORD` and `YOUR_KEY_PASSWORD`

Files created (never commit to GitHub):
- `android\keystore\swimiq-upload.jks`
- `android\key.properties`

**Back up `swimiq-upload.jks` + passwords** to USB / 1Password. Losing them means you cannot update the same Play listing.

---

## Build the Google Play bundle (.aab)

1. Ensure **`S:\swimiq\.env`** has real `SUPABASE_URL` and `SUPABASE_ANON_KEY`
2. Pull latest code:

```bat
cd S:\swimiq
git pull origin cursor/android-aab-pdf-export-17e8
```

3. Double-click **`SWIMIQ-BUILD-AAB-NOW.bat`**

Success output:
```
build\app\outputs\bundle\release\app-release.aab
```

### If it fails
Double-click **`DIAGNOSE-ANDROID.bat`** — writes full log to `android-diagnose-log.txt`. Read the **last 40 lines** for the real error.

Manual build (for logging):
```bat
cd S:\swimiq
flutter pub get
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## Upload to Google Play Console

1. [Google Play Console](https://play.google.com/console) → Create app (if new)
2. **Package name** must match: `com.swimiq.swimiq`
3. **Release** → **Production** (or Internal testing first) → **Create new release**
4. Upload **`app-release.aab`**
5. Complete store listing: icon, screenshots, privacy policy URL, content rating questionnaire

### Internal / closed testing (community testers)

**Website (swimiqapp.com) uploads do NOT change Play testing links.**  
GoDaddy / Flutter web work is separate from the Android AAB on Google Play.

| What | Link / ID |
|------|-----------|
| **Package name (never change)** | `com.swimiq.swimiq` |
| **Public store page** (only after Production publish) | `https://play.google.com/store/apps/details?id=com.swimiq.swimiq` |
| **Internal / closed testing join link** | Created in Play Console → Testing → Internal testing (or Closed testing) → **Testers** → copy **join on the web** / opt-in URL. It looks like `https://play.google.com/apps/internaltest/...` or a Console share link. **That exact URL is owned by Play Console — not by this GitHub repo.** |

**Testers should keep using the Play Console join link you already sent them** unless you create a new testing track and send a new link. Rebuilding the website or merging web/Analyze PRs does not invalidate that Play link.

### Internal testing (recommended first)
- **Internal testing** track → add testers by email → upload same `.aab` → testers install via Play join link above

---

## APK vs AAB

| File | Use |
|------|-----|
| **`.aab`** | **Google Play** (required for new apps) |
| **`.apk`** | Side-load to your phone only (`SWIMIQ-BUILD-ANDROID-NOW.bat`) |

---

## Version bumps (each Play upload)

Edit **`pubspec.yaml`**:
```yaml
version: 1.0.1+2   # 1.0.1 = user-facing, +2 = versionCode (must increase every upload)
```

Then rebuild AAB.

---

## True PDF export (résumé)

After pulling latest:
- **Passport → Recruiting Center → Best Times Résumé → Export PDF**
- Share/save a real `.pdf` on phone and desktop
- **Print / preview PDF** opens system print dialog (Save as PDF on Chrome)

No extra setup beyond `flutter pub get`.

---

## Quick checklist

- [ ] Android Studio installed, `flutter doctor` green for Android
- [ ] `GENERATE-ANDROID-KEYSTORE.bat` run once
- [ ] `android\key.properties` filled in
- [ ] `.env` has Supabase keys
- [ ] `SWIMIQ-BUILD-AAB-NOW.bat` → `app-release.aab`
- [ ] Upload to Play Console Internal testing
- [ ] Test PDF export on device
