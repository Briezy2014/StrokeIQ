-- Milestone 9: Video Engine V2 tables + RLS
-- Private analysis jobs, metrics, events, reports, artifacts, feedback, model versions.
-- Does not delete legacy swim_videos / swim_video_analyses.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- model_versions registry
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.model_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  component text NOT NULL,
  model_name text NOT NULL,
  model_version text NOT NULL,
  notes text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (component, model_name, model_version)
);

-- ---------------------------------------------------------------------------
-- video_analysis_jobs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swimmer_key text NOT NULL,
  swim_video_id uuid REFERENCES public.swim_videos(id) ON DELETE SET NULL,
  video_id text NOT NULL,
  storage_bucket text NOT NULL DEFAULT 'swim-videos',
  storage_path text NOT NULL,
  status text NOT NULL DEFAULT 'queued',
  stage text NOT NULL DEFAULT 'queued',
  progress double precision NOT NULL DEFAULT 0,
  engine_version text NOT NULL,
  engine_name text NOT NULL DEFAULT 'video_engine_v2',
  request_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  error_code text,
  error_message text,
  retry_count integer NOT NULL DEFAULT 0,
  limitations text[] NOT NULL DEFAULT '{}',
  model_versions jsonb NOT NULL DEFAULT '{}'::jsonb,
  shared_with uuid[] NOT NULL DEFAULT '{}',
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT video_analysis_jobs_status_check CHECK (
    status = ANY (ARRAY[
      'queued','validating','preprocessing','detecting_swimmer','estimating_pose',
      'detecting_events','calculating_metrics','validating_results','generating_report',
      'completed','completed_with_limitations','failed','cancelled'
    ])
  )
);

CREATE INDEX IF NOT EXISTS video_analysis_jobs_user_id_idx
  ON public.video_analysis_jobs (user_id);
CREATE INDEX IF NOT EXISTS video_analysis_jobs_swimmer_key_idx
  ON public.video_analysis_jobs (swimmer_key);
CREATE INDEX IF NOT EXISTS video_analysis_jobs_video_id_idx
  ON public.video_analysis_jobs (video_id);
CREATE INDEX IF NOT EXISTS video_analysis_jobs_status_idx
  ON public.video_analysis_jobs (status);

-- ---------------------------------------------------------------------------
-- video_analysis_metrics
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.video_analysis_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metric_id text NOT NULL,
  name text NOT NULL,
  display_name text,
  value double precision,
  unit text,
  confidence double precision,
  confidence_label text,
  classification text,
  method text,
  unavailable_reason text,
  supporting_frame_numbers integer[] NOT NULL DEFAULT '{}',
  supporting_timestamps_ms double precision[] NOT NULL DEFAULT '{}',
  quality_flags text[] NOT NULL DEFAULT '{}',
  limitations text[] NOT NULL DEFAULT '{}',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS video_analysis_metrics_job_id_idx
  ON public.video_analysis_metrics (job_id);

-- ---------------------------------------------------------------------------
-- video_analysis_events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.video_analysis_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id text NOT NULL,
  event_type text NOT NULL,
  timestamp_ms double precision,
  frame_number integer,
  confidence double precision,
  confidence_label text,
  method text,
  unavailable_reason text,
  supporting_frames integer[] NOT NULL DEFAULT '{}',
  quality_flags text[] NOT NULL DEFAULT '{}',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS video_analysis_events_job_id_idx
  ON public.video_analysis_events (job_id);

-- ---------------------------------------------------------------------------
-- video_analysis_reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.video_analysis_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  model_name text,
  model_version text,
  prompt_version text,
  schema_version text,
  report_json jsonb,
  failure_code text,
  failure_reason text,
  referenced_metric_ids text[] NOT NULL DEFAULT '{}',
  referenced_event_ids text[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (job_id)
);

-- ---------------------------------------------------------------------------
-- video_analysis_artifacts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_artifacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.video_analysis_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artifact_key text NOT NULL,
  storage_bucket text,
  storage_path text,
  local_path text,
  content_type text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS video_analysis_artifacts_job_id_idx
  ON public.video_analysis_artifacts (job_id);

-- ---------------------------------------------------------------------------
-- video_analysis_feedback
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_analysis_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.video_analysis_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feedback_type text NOT NULL DEFAULT 'general',
  message text NOT NULL,
  incorrect_fields text[] NOT NULL DEFAULT '{}',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Ownership helper: user owns job OR is in shared_with
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.user_can_access_analysis_job(job_row public.video_analysis_jobs)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT job_row.deleted_at IS NULL
    AND (
      job_row.user_id = auth.uid()
      OR auth.uid() = ANY (job_row.shared_with)
    );
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.model_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_analysis_feedback ENABLE ROW LEVEL SECURITY;

-- model_versions: authenticated read of active rows
DROP POLICY IF EXISTS model_versions_select_authenticated ON public.model_versions;
CREATE POLICY model_versions_select_authenticated ON public.model_versions
  FOR SELECT TO authenticated
  USING (active = true);

-- jobs
DROP POLICY IF EXISTS video_analysis_jobs_select_own ON public.video_analysis_jobs;
CREATE POLICY video_analysis_jobs_select_own ON public.video_analysis_jobs
  FOR SELECT TO authenticated
  USING (public.user_can_access_analysis_job(video_analysis_jobs));

DROP POLICY IF EXISTS video_analysis_jobs_insert_own ON public.video_analysis_jobs;
CREATE POLICY video_analysis_jobs_insert_own ON public.video_analysis_jobs
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_jobs_update_own ON public.video_analysis_jobs;
CREATE POLICY video_analysis_jobs_update_own ON public.video_analysis_jobs
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_jobs_delete_own ON public.video_analysis_jobs;
CREATE POLICY video_analysis_jobs_delete_own ON public.video_analysis_jobs
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- child tables: access via parent job ownership
DROP POLICY IF EXISTS video_analysis_metrics_select_own ON public.video_analysis_metrics;
CREATE POLICY video_analysis_metrics_select_own ON public.video_analysis_metrics
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.video_analysis_jobs j
      WHERE j.id = video_analysis_metrics.job_id
        AND public.user_can_access_analysis_job(j)
    )
  );

DROP POLICY IF EXISTS video_analysis_metrics_insert_own ON public.video_analysis_metrics;
CREATE POLICY video_analysis_metrics_insert_own ON public.video_analysis_metrics
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_events_select_own ON public.video_analysis_events;
CREATE POLICY video_analysis_events_select_own ON public.video_analysis_events
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.video_analysis_jobs j
      WHERE j.id = video_analysis_events.job_id
        AND public.user_can_access_analysis_job(j)
    )
  );

DROP POLICY IF EXISTS video_analysis_events_insert_own ON public.video_analysis_events;
CREATE POLICY video_analysis_events_insert_own ON public.video_analysis_events
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_reports_select_own ON public.video_analysis_reports;
CREATE POLICY video_analysis_reports_select_own ON public.video_analysis_reports
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.video_analysis_jobs j
      WHERE j.id = video_analysis_reports.job_id
        AND public.user_can_access_analysis_job(j)
    )
  );

DROP POLICY IF EXISTS video_analysis_reports_insert_own ON public.video_analysis_reports;
CREATE POLICY video_analysis_reports_insert_own ON public.video_analysis_reports
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_artifacts_select_own ON public.video_analysis_artifacts;
CREATE POLICY video_analysis_artifacts_select_own ON public.video_analysis_artifacts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.video_analysis_jobs j
      WHERE j.id = video_analysis_artifacts.job_id
        AND public.user_can_access_analysis_job(j)
    )
  );

DROP POLICY IF EXISTS video_analysis_artifacts_insert_own ON public.video_analysis_artifacts;
CREATE POLICY video_analysis_artifacts_insert_own ON public.video_analysis_artifacts
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_feedback_select_own ON public.video_analysis_feedback;
CREATE POLICY video_analysis_feedback_select_own ON public.video_analysis_feedback
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS video_analysis_feedback_insert_own ON public.video_analysis_feedback;
CREATE POLICY video_analysis_feedback_insert_own ON public.video_analysis_feedback
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Harden swim_videos ownership when user_id column exists (additive)
-- ---------------------------------------------------------------------------
ALTER TABLE public.swim_videos
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS swim_videos_user_id_idx ON public.swim_videos (user_id);

-- Prefer owner RLS for new rows; keep legacy open policy only for null user_id rows
-- during dual-engine period (video_engine_legacy). New V2 uploads should set user_id.
DROP POLICY IF EXISTS swim_videos_select_owner_or_legacy ON public.swim_videos;
CREATE POLICY swim_videos_select_owner_or_legacy ON public.swim_videos
  FOR SELECT TO authenticated
  USING (user_id IS NULL OR user_id = auth.uid());

DROP POLICY IF EXISTS swim_videos_insert_owner ON public.swim_videos;
CREATE POLICY swim_videos_insert_owner ON public.swim_videos
  FOR INSERT TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

DROP POLICY IF EXISTS swim_videos_update_owner ON public.swim_videos;
CREATE POLICY swim_videos_update_owner ON public.swim_videos
  FOR UPDATE TO authenticated
  USING (user_id IS NULL OR user_id = auth.uid())
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Note: legacy policy "swim_videos_all" may still exist; operators should drop it
-- after verifying V2 + ownership backfill:
--   DROP POLICY IF EXISTS "swim_videos_all" ON public.swim_videos;

COMMENT ON TABLE public.video_analysis_jobs IS
  'Elote Video Engine V2 jobs. Flutter feature flag: video_engine_v2.';
COMMENT ON TABLE public.video_analysis_reports IS
  'Gemini coaching narrative only; deterministic metrics remain source of truth.';
