# Morning start (Kara / Windows)

## One double-click

1. Close old Elite / SwimIQ windows
2. Double-click:

`Desktop\StrokeIQ\START-SWIMIQ-WITH-ELITE.bat`

3. Wait until http://127.0.0.1:8080/health shows:
   - `"status":"ok"`
   - `"ffmpeg_available":true`
   - `"storage_download_configured":true`
4. Keep **both** windows open
5. Sign in → Elite tab → green connected → **Run Elite Analysis**
   - After AI legal consent, analysis starts immediately (no extra confirm screen)

## If health shows storage_download_configured:false

Your `swimiq\.env` Supabase URL/anon key could not be copied into
`services\video_analysis\.env`. Open both files, copy those two lines, save,
restart the bat.

## Coach share link

See **COACH-ACCESS.md** → https://swimiqapp.com
