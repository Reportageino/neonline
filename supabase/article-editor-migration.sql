-- Neon Line v1: run once in Supabase SQL Editor after the base schema.
-- Adds accessible metadata for article featured images.
alter table public.articles
  add column if not exists cover_title text not null default '',
  add column if not exists cover_alt text not null default '';

-- Public bucket for published article images. Admin/editor uploads are restricted by authenticated profile role.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('article-images', 'article-images', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

-- Public can read article images; only signed-in staff can upload/update/delete.
drop policy if exists "Public read article images" on storage.objects;
create policy "Public read article images" on storage.objects for select
using (bucket_id = 'article-images');

drop policy if exists "Staff upload article images" on storage.objects;
create policy "Staff upload article images" on storage.objects for insert to authenticated
with check (bucket_id = 'article-images' and public.is_staff());

drop policy if exists "Staff update article images" on storage.objects;
create policy "Staff update article images" on storage.objects for update to authenticated
using (bucket_id = 'article-images' and public.is_staff())
with check (bucket_id = 'article-images' and public.is_staff());

drop policy if exists "Staff delete article images" on storage.objects;
create policy "Staff delete article images" on storage.objects for delete to authenticated
using (bucket_id = 'article-images' and public.is_staff());
