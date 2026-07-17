-- Milestone 9 follow-up: remove legacy open-table policies that undermine
-- owner RLS added in 005_video_analysis_engine_v2.sql.
-- Safe to re-run (IF EXISTS). Apply after verifying V2 + user_id backfill.

DROP POLICY IF EXISTS swim_videos_all ON public.swim_videos;
DROP POLICY IF EXISTS "swim_videos_all" ON public.swim_videos;

DROP POLICY IF EXISTS swim_video_analyses_all ON public.swim_video_analyses;
DROP POLICY IF EXISTS "swim_video_analyses_all" ON public.swim_video_analyses;

COMMENT ON TABLE public.swim_videos IS
  'Swim video metadata. Owner RLS required; open swim_videos_all policy removed.';
