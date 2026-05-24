-- Persist in-app notification read state per account.
-- This keeps read notifications hidden after app restart/reinstall.

CREATE TABLE IF NOT EXISTS public.notification_reads (
  employee_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  read_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (employee_id, notification_id)
);

ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Karyawan baca notification read sendiri"
  ON public.notification_reads;
CREATE POLICY "Karyawan baca notification read sendiri"
  ON public.notification_reads FOR SELECT
  USING (employee_id = auth.uid());

DROP POLICY IF EXISTS "Karyawan buat notification read sendiri"
  ON public.notification_reads;
CREATE POLICY "Karyawan buat notification read sendiri"
  ON public.notification_reads FOR INSERT
  WITH CHECK (employee_id = auth.uid());

DROP POLICY IF EXISTS "Karyawan update notification read sendiri"
  ON public.notification_reads;
CREATE POLICY "Karyawan update notification read sendiri"
  ON public.notification_reads FOR UPDATE
  USING (employee_id = auth.uid())
  WITH CHECK (employee_id = auth.uid());
