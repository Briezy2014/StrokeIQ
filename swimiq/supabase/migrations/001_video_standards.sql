-- SwimIQ V1 extension: video upload, AI analysis, USA standards
-- Run this in Supabase Dashboard → SQL Editor
-- Matches live schema: swim_videos.id is UUID; distance is text.

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

CREATE TABLE IF NOT EXISTS public.usa_time_standards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  age_group text NOT NULL,
  gender text NOT NULL,
  stroke text NOT NULL,
  distance integer NOT NULL,
  course text NOT NULL,
  standard_level text NOT NULL,
  time_seconds numeric NOT NULL,
  UNIQUE (age_group, gender, stroke, distance, course, standard_level)
);

ALTER TABLE public.swim_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swim_video_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usa_time_standards ENABLE ROW LEVEL SECURITY;

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

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'usa_time_standards' AND policyname = 'usa_time_standards_all'
  ) THEN
    CREATE POLICY "usa_time_standards_all" ON public.usa_time_standards
      FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- Storage: create bucket "swim-videos" in Dashboard → Storage (public read recommended for V1)
