-- Perfiles de usuario con nombre visible e imagen
alter table public.profiles
add column if not exists display_name text;

alter table public.profiles
add column if not exists avatar_path text;

alter table public.profiles
add column if not exists updated_at timestamptz not null default now();

-- RLS: cada usuario puede leer perfiles de miembros de sus familias y editar el suyo
alter table public.profiles enable row level security;

drop policy if exists "profiles read own" on public.profiles;
drop policy if exists "profiles read family members" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
drop policy if exists "profiles insert own" on public.profiles;

create policy "profiles read own"
on public.profiles
for select
using (id = auth.uid());

create policy "profiles read family members"
on public.profiles
for select
using (
  exists (
    select 1
    from public.family_members me
    join public.family_members other_member
      on other_member.family_id = me.family_id
    where me.user_id = auth.uid()
      and other_member.user_id = profiles.id
  )
);

create policy "profiles update own"
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

create policy "profiles insert own"
on public.profiles
for insert
with check (id = auth.uid());

-- Realtime opcional para refrescar nombres/fotos
alter table public.profiles replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.profiles;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end;
$$;

-- Políticas básicas de Storage para avatares dentro del bucket family-files.
-- Si ya tienes políticas de Storage funcionando, estas no deberían romperlas.
insert into storage.buckets (id, name, public)
values ('family-files', 'family-files', false)
on conflict (id) do nothing;

drop policy if exists "avatar upload own" on storage.objects;
drop policy if exists "avatar read authenticated" on storage.objects;
drop policy if exists "avatar update own" on storage.objects;

create policy "avatar upload own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'family-files'
  and name like ('profile-avatars/' || auth.uid()::text || '/%')
);

create policy "avatar update own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'family-files'
  and name like ('profile-avatars/' || auth.uid()::text || '/%')
)
with check (
  bucket_id = 'family-files'
  and name like ('profile-avatars/' || auth.uid()::text || '/%')
);

create policy "avatar read authenticated"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'family-files'
  and name like 'profile-avatars/%'
);
