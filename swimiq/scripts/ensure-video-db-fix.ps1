# Creates video database fix helpers in the swimiq folder (works offline, no git pull needed).
param(
    [string]$SwimIqRoot = (Split-Path $PSScriptRoot -Parent)
)

function Ensure-VideoDbFix {
    param([string]$Root = $SwimIqRoot)

    $Root = (Resolve-Path -LiteralPath $Root).Path
    $supabaseDir = Join-Path $Root 'supabase'
    New-Item -ItemType Directory -Force -Path $supabaseDir | Out-Null

    $sql = @'
-- Run once in Supabase Dashboard -> SQL Editor
-- Fixes: "Could not find the table public.swim_video_analyses" (PGRST205)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.swim_videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swimmer text,
  swimmer_name text NOT NULL,
  title text,
  stroke text,
  distance text,
  course text,
  storage_path text NOT NULL,
  video_url text,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.swim_video_analyses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swim_video_id uuid REFERENCES public.swim_videos(id) ON DELETE CASCADE,
  swimmer text,
  swimmer_name text NOT NULL,
  summary text,
  strengths text,
  improvements text,
  technique_score integer,
  pace_score integer,
  overall_score integer,
  analysis_json jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.swim_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swim_video_analyses ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'swim_videos' AND policyname = 'swim_videos_all'
  ) THEN
    CREATE POLICY "swim_videos_all" ON public.swim_videos
      FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'swim_video_analyses' AND policyname = 'swim_video_analyses_all'
  ) THEN
    CREATE POLICY "swim_video_analyses_all" ON public.swim_video_analyses
      FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
'@

    $pasteTxt = @"
================================================================================
  KARA - PASTE THIS IN SUPABASE (fixes Delete + Video AI save errors)
================================================================================

WHEN YOU NEED THIS
------------------
- Delete video says deleted but the video comes back
- Analyze spins forever or shows swim_video_analyses / PGRST205 errors

WHAT TO DO (website only - no Node.js needed)
---------------------------------------------
1. Chrome -> https://supabase.com/dashboard
2. Open your SwimIQ project
3. Click SQL Editor in the left menu
4. Click New query
5. Scroll down to ---- START SQL ---- in this file
6. Select from ---- START SQL ---- through ---- END SQL ----
7. Copy (Ctrl+C), paste into Supabase SQL Editor (Ctrl+V)
8. Click RUN (green button)
9. Should say Success

THEN ON YOUR PC
---------------
1. KARA-GEMINI-FIX-NOW.bat   (deploys video AI server)
2. KARA-CLICK-THIS.bat       (open SwimIQ)
3. Video tab -> Delete or Analyze again

================================================================================
---- START SQL ----
$($sql.TrimEnd())
---- END SQL ----
================================================================================
"@

    $fixBat = @'
@echo off
title SwimIQ - Fix video database
cd /d "%~dp0"
echo.
echo ============================================================
echo   FIX VIDEO DELETE + AI ANALYSIS DATABASE
echo ============================================================
echo.
echo DO THIS ONCE on the Supabase website:
echo   1. https://supabase.com/dashboard
echo   2. Your SwimIQ project - SQL Editor - New query
echo   3. Copy ALL text from the Notepad file that opens
echo   4. Paste - RUN - Success
echo.
echo THEN: KARA-GEMINI-FIX-NOW.bat - Video tab - Delete or Analyze
echo.
set "PASTEFILE=%~dp0KARA-PASTE-THIS-IN-SUPABASE.txt"
if exist "%PASTEFILE%" (
  start notepad "%PASTEFILE%"
) else (
  start https://supabase.com/dashboard/project/bryurwyeosbffvfpdpbv/sql/new
)
echo.
pause
'@

    Set-Content -LiteralPath (Join-Path $Root 'supabase\fix_video_tables.sql') -Value $sql.TrimEnd() -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Root 'KARA-PASTE-THIS-IN-SUPABASE.txt') -Value $pasteTxt -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Root 'FIX-VIDEO-DATABASE.bat') -Value $fixBat -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $Root 'KARA-FIX-VIDEO-DATABASE.bat') -Value "@echo off`r`ncd /d `"%~dp0`"`r`ncall `"%~dp0FIX-VIDEO-DATABASE.bat`"`r`n" -Encoding ASCII

    Write-Host "[OK] Created FIX-VIDEO-DATABASE.bat and KARA-PASTE-THIS-IN-SUPABASE.txt" -ForegroundColor Green
}

if ($MyInvocation.InvocationName -ne '.') {
    Ensure-VideoDbFix
}
