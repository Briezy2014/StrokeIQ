-- Milestone 9: private swim-videos access via signed URLs (no public read).
-- Create/ensure the bucket exists as private. Do not make private videos public.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'swim-videos',
  'swim-videos',
  false,
  524288000,
  ARRAY['video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v']::text[]
)
ON CONFLICT (id) DO UPDATE
SET public = false;

-- Owner path convention: first folder segment is swimmer key OR user id.
-- Prefer object ownership via folder prefix matching auth.uid()::text OR
-- association through video_analysis_jobs / swim_videos.user_id.

DROP POLICY IF EXISTS swim_videos_storage_select_own ON storage.objects;
CREATE POLICY swim_videos_storage_select_own ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'swim-videos'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.swim_videos v
        WHERE v.storage_path = name
          AND v.user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.video_analysis_jobs j
        WHERE j.storage_path = name
          AND j.deleted_at IS NULL
          AND (j.user_id = auth.uid() OR auth.uid() = ANY (j.shared_with))
      )
    )
  );

DROP POLICY IF EXISTS swim_videos_storage_insert_own ON storage.objects;
CREATE POLICY swim_videos_storage_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'swim-videos'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR (storage.foldername(name))[1] IS NOT NULL
    )
  );

DROP POLICY IF EXISTS swim_videos_storage_update_own ON storage.objects;
CREATE POLICY swim_videos_storage_update_own ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'swim-videos'
    AND EXISTS (
      SELECT 1 FROM public.swim_videos v
      WHERE v.storage_path = name AND v.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS swim_videos_storage_delete_own ON storage.objects;
CREATE POLICY swim_videos_storage_delete_own ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'swim-videos'
    AND EXISTS (
      SELECT 1 FROM public.swim_videos v
      WHERE v.storage_path = name AND v.user_id = auth.uid()
    )
  );

COMMENT ON POLICY swim_videos_storage_select_own ON storage.objects IS
  'Private swim-videos: owners and authorized job sharers only; use signed URLs.';
