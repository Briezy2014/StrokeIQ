ALTER TABLE public.swim_videos
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS swim_videos_user_id_idx
  ON public.swim_videos (user_id);

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

NOTIFY pgrst, 'reload schema';
