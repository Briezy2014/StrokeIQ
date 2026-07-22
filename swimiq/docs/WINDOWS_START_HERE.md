# Windows — Start SwimIQ (after PR #84 on main)

**Do not use** `Desktop\StrokeIQ` in PowerShell. That folder often does not exist on this PC (OneDrive / renamed folders). That wrong path is why `cd` keeps failing.

## Find your real folder first

1. In File Explorer, open your SwimIQ / StrokeIQ project folder (search This PC for `pubspec.yaml` inside a `swimiq` folder).
2. Or from the repo root, double-click **`FIND-SWIMIQ-FOLDER.bat`** (searches the PC and opens the real `swimiq` folder).
3. Or in PowerShell (from any folder):

```powershell
Get-ChildItem -Path $env:USERPROFILE -Filter pubspec.yaml -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -match '\\swimiq\\pubspec\.yaml$' } |
  Select-Object -ExpandProperty DirectoryName
```

Then:

```powershell
cd "PASTE_THE_PATH_IT_PRINTED"
git checkout main
git pull origin main
dir
```

If you already use drive **`S:`**:

```powershell
cd S:\swimiq
git pull origin main
```

## Every launch (on main after #84)

1. Double-click **`swimiq\START-SWIMIQ.bat`** (this is what exists on `main`).
2. For Elite/Elote local analysis, follow **`docs/VIDEO_ENGINE_V2_MORNING_LAUNCH.md`**.
3. Prefer **localhost** for Elite. Public **swimiqapp.com** cannot reach Elote on your laptop until Elote is hosted.

## Important: bats that are NOT on main

| File | On `main`? |
|------|------------|
| `swimiq\START-SWIMIQ.bat` | Yes |
| `START-SWIMIQ-WITH-ELITE.bat` | No (older branch only) |
| `DEPLOY-GEMINI-VIDEO.bat` | No (stopgap PR #87 only) |

If a guide tells you to open a bat and File Explorer does not show it, you are either in the wrong folder or on a branch that never had that file — do not keep retrying `Desktop\StrokeIQ`.
