# Windows — Start SwimIQ

**Do not use** `cd Desktop\StrokeIQ` in PowerShell. That path often does not exist (OneDrive / renamed folders).

## Find your real folder

If you already use drive **S:** (recommended):

```powershell
cd S:\swimiq
git checkout main
git pull origin main
```

Or search:

```powershell
Get-ChildItem -Path $env:USERPROFILE -Filter pubspec.yaml -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -match '\\swimiq\\pubspec\.yaml$' } |
  Select-Object -ExpandProperty DirectoryName
```

From the **repo root** (parent of `swimiq`), you can also run `FIND-SWIMIQ-FOLDER.ps1` / `FIND-SWIMIQ-FOLDER.bat` when present.

## Start the app

1. Prefer: **`S:\START-SWIMIQ-WITH-ELITE.bat`** (repo root) — starts Elite server + Chrome  
2. Or: **`S:\swimiq\START-SWIMIQ.bat`** — app only  
3. Keep windows open. Use **localhost**, not only swimiqapp.com, for local Elite.

## What the nav should look like (current product)

- **6 tabs:** Dashboard · PBs · **Log** · Goals · **Elite** (or Video) · Passport  
- **Log** includes training + meets (not separate Add / Meets tabs)  
- Passport shows the **recruiting wallet card**

If you still see separate Log / Add / Meets, you are on an old checkout — run `git pull origin main` after the restore PR is merged.
