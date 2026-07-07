# Tonight — open SwimIQ in Chrome (3 steps)

You do **not** need ten PowerShell commands. Every nightly failure has been the same three things:

1. Wrong folder (`StrokeIQ` instead of `StrokeIQ\swimiq`)
2. Windows username spaces (`Kara Williams` → use the launcher, not raw `flutter run`)
3. Supabase keys (`.env` in **swimiq** folder, not the parent folder)

---

## Every night — do ONLY this

### Step 1 — Pull latest (once, before preview)

In PowerShell:

```powershell
cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ\swimiq"
git pull origin main
```

### Step 2 — `.env` lives here (one time setup)

File must be:

`C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ\swimiq\.env`

Not in the parent `StrokeIQ` folder.

Contents (two lines):

```
SUPABASE_URL=https://bryurwyeosbffvfpdpbv.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Get keys: Supabase → Project Settings → API.

### Step 3 — Double-click

In File Explorer, open the **swimiq** folder and double-click:

**`LAUNCH-CHROME.bat`**

Wait for Chrome. Sign in. Scroll every tab.

---

## After Chrome looks good → GoDaddy

Double-click or run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-web-godaddy.ps1
```

Upload everything in `build\web\` to GoDaddy `public_html`.

---

## Do NOT run these manually anymore

- `flutter run -d chrome` (from wrong folder or without keys)
- `copy .env.example .env` from `StrokeIQ` root
- Pasting `SUPABASE_ANON_KEY=...` as its own PowerShell line

Use **`LAUNCH-CHROME.bat`** only.

---

## If LAUNCH-CHROME.bat fails

Read the message it prints:

| Message | Fix |
|---------|-----|
| Created `.env` — paste keys | Notepad opens → paste URL + anon key → save → double-click again |
| Flutter not found | Install Flutter to `C:\flutter` |
| `'C:\Users\Kara' is not recognized` | You skipped the bat file — use `LAUNCH-CHROME.bat` |
