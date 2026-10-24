-- Neon Line v7: idempotent public contact form INSERT policy.
-- Public visitors may submit a lead, but must not read, update, or delete leads.
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

-- Remove prior public INSERT policy names used in earlier iterations to avoid
-- permissive policies being OR-ed together with weaker validation.
DROP POLICY IF EXISTS "public submit lead" ON public.leads;
DROP POLICY IF EXISTS "Public can submit leads" ON public.leads;
DROP POLICY IF EXISTS "Allow public lead submissions" ON public.leads;
DROP POLICY IF EXISTS "Anyone can insert leads" ON public.leads;
DROP POLICY IF EXISTS "public insert leads" ON public.leads;

CREATE POLICY "public submit lead"
ON public.leads
FOR INSERT
TO anon, authenticated
WITH CHECK (
  length(trim(name)) BETWEEN 2 AND 120
  AND length(trim(phone)) BETWEEN 5 AND 40
  AND length(coalesce(email, '')) <= 254
  AND length(coalesce(service, '')) <= 150
  AND length(coalesce(details, '')) <= 5000
  AND status = 'new'
);

GRANT INSERT ON TABLE public.leads TO anon, authenticated;
-- Deliberately do not grant SELECT, UPDATE, or DELETE to public roles.
NOTIFY pgrst, 'reload schema';
