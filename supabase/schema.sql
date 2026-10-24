-- Neon Line CMS schema for Supabase PostgreSQL
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'admin' check (role in ('admin','editor')),
  created_at timestamptz not null default now()
);
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('admin','editor'));
$$;
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  description text not null default '', created_at timestamptz not null default now()
);
create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  excerpt text not null default '', body text not null default '', cover_url text not null default '',
  category_id uuid references public.categories(id) on delete set null,
  status text not null default 'draft' check(status in ('draft','published')),
  seo_title text not null default '', seo_description text not null default '', published_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.pages (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  body text not null default '', status text not null default 'draft' check(status in ('draft','published')),
  seo_title text not null default '', seo_description text not null default '', updated_at timestamptz not null default now()
);
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  summary text not null default '', body text not null default '', icon text not null default '✦',
  status text not null default 'published' check(status in ('draft','published')), sort_order int not null default 0,
  seo_title text not null default '', seo_description text not null default '', created_at timestamptz not null default now()
);
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique,
  client_name text not null default '', category text not null default '', summary text not null default '',
  image_url text not null default '', project_url text not null default '', status text not null default 'published' check(status in ('draft','published')),
  created_at timestamptz not null default now()
);
create table if not exists public.site_settings (
  key text primary key, value jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now()
);
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(), name text not null, phone text not null,
  email text not null default '', service text not null default '', details text not null default '',
  status text not null default 'new' check(status in ('new','in_progress','closed')),
  created_at timestamptz not null default now()
);
create index if not exists articles_status_published_idx on public.articles(status,published_at desc);
create index if not exists leads_created_at_idx on public.leads(created_at desc);
-- RLS: enable on every table
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.articles enable row level security;
alter table public.pages enable row level security;
alter table public.services enable row level security;
alter table public.projects enable row level security;
alter table public.site_settings enable row level security;
alter table public.leads enable row level security;
-- public can read published content only
create policy "profiles staff read own" on public.profiles for select to authenticated using (id=auth.uid() or public.is_staff());
create policy "staff manage profiles" on public.profiles for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read categories" on public.categories for select to anon, authenticated using (true);
create policy "staff manage categories" on public.categories for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read published articles" on public.articles for select to anon, authenticated using (status='published' or public.is_staff());
create policy "staff manage articles" on public.articles for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read published pages" on public.pages for select to anon, authenticated using (status='published' or public.is_staff());
create policy "staff manage pages" on public.pages for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read published services" on public.services for select to anon, authenticated using (status='published' or public.is_staff());
create policy "staff manage services" on public.services for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read published projects" on public.projects for select to anon, authenticated using (status='published' or public.is_staff());
create policy "staff manage projects" on public.projects for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "public read public settings" on public.site_settings for select to anon, authenticated using (key in ('seo','contact','social'));
create policy "staff manage settings" on public.site_settings for all to authenticated using (public.is_staff()) with check (public.is_staff());
-- Anonymous visitors may submit leads, but cannot read or modify them.
create policy "public submit lead" on public.leads for insert to anon, authenticated with check (length(trim(name)) between 2 and 120 and length(trim(phone)) between 5 and 40 and length(details) <= 5000);
create policy "staff read leads" on public.leads for select to authenticated using (public.is_staff());
create policy "staff update leads" on public.leads for update to authenticated using (public.is_staff()) with check (public.is_staff());
-- Seed initial service rows (safe to rerun)
insert into public.services(title,slug,summary,icon,sort_order) values
('طراحی سایت','web-design','طراحی وب‌سایت سریع، واکنش‌گرا و متناسب با مسیر رشد کسب‌وکار.','⌘',1),
('سئو و رشد ارگانیک','seo','بهبود ساختار فنی، محتوایی و دیده‌شدن در نتایج جست‌وجو.','↗',2),
('تبلیغات گوگل','google-ads','مدیریت کمپین‌های هدفمند با تمرکز بر کیفیت سرنخ و بازدهی.','◎',3),
('بازاریابی محتوایی','content-marketing','تبدیل دانش برند به محتوایی مفید، منسجم و قابل‌اندازه‌گیری.','✳',4),
('تحلیل و بهینه‌سازی نرخ تبدیل','cro','شناسایی اصطکاک‌های مسیر مشتری و بهبود تجربه تبدیل.','⌁',5)
on conflict(slug) do nothing;
