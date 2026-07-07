-- Lock USA time standards to read-only for app users.
-- Standards ship in the app bundle; writes are owner/ops only (service role or SQL Editor).

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'usa_time_standards'
      AND policyname = 'usa_time_standards_all'
  ) THEN
    DROP POLICY "usa_time_standards_all" ON public.usa_time_standards;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'usa_time_standards'
      AND policyname = 'usa_time_standards_read'
  ) THEN
    CREATE POLICY "usa_time_standards_read" ON public.usa_time_standards
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;
