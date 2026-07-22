# Tonight — open SwimIQ in Chrome (3 steps)

Every `'C:\Users\Kara' is not recognized` error means Flutter ran from a **path with spaces**.
Your PC username is `Kara Williams` — Flutter **cannot** run from that path directly.

---

## FIX ONCE (do this tonight if Chrome keeps failing)

1. In File Explorer → open **`swimiq`** folder
2. Double-click **`FIX-KARA-PATHS.bat`**
3. **Close ALL PowerShell windows**
4. **Close VS Code completely**
5. Re-open VS Code

This maps `F:` = Flutter, `S:` = project, and saves `PUB_CACHE=S:\pub-cache` permanently.

---

## EVERY NIGHT (after the one-time fix)

1. Make sure **`swimiq\.env`** has your Supabase URL + anon key
2. Double-click **`LAUNCH-CHROME.bat`**
3. Wait for Chrome — sign in — review tabs
4. When happy → `scripts\build-web-godaddy.ps1` → GoDaddy

---

## NEVER do these (they cause the Kara error every night)

- `flutter run -d chrome` typed manually
- VS Code **Run / F5** button for Flutter
- Running from `C:\Users\Kara Williams\...` in the terminal prompt

Your prompt must show **`S:\swimiq>`** not `C:\Users\Kara Williams\...`

---

## .env file location

Must be:

`swimiq\.env`

```
SUPABASE_URL=https://bryurwyeosbffvfpdpbv.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

One `https://` only — not `https:https//`

---

## VS Code (optional)

**Terminal → Run Task → SwimIQ: Launch Chrome (Kara safe)**

Do not use the default Flutter Run button.
