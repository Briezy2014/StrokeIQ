-- Allow Elite pipeline "downloading" stage when fetching video from Storage.
ALTER TABLE public.video_analysis_jobs
  DROP CONSTRAINT IF EXISTS video_analysis_jobs_status_check;

ALTER TABLE public.video_analysis_jobs
  ADD CONSTRAINT video_analysis_jobs_status_check CHECK (
    status = ANY (ARRAY[
      'queued',
      'downloading',
      'validating',
      'preprocessing',
      'detecting_swimmer',
      'estimating_pose',
      'detecting_events',
      'calculating_metrics',
      'validating_results',
      'generating_report',
      'completed',
      'completed_with_limitations',
      'failed',
      'cancelled'
    ])
  );
