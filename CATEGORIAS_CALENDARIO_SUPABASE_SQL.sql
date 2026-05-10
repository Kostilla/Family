-- Categorías de calendario con color por familia
create extension if not exists pgcrypto;

create table if not exists public.event_categories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  color text not null default '#3B82F6',
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, name)
);

alter table public.events
add column if not exists category_id uuid references public.event_categories(id) on delete set null;

alter table public.event_categories enable row level security;

drop policy if exists "event categories select" on public.event_categories;
drop policy if exists "event categories insert" on public.event_categories;
drop policy if exists "event categories update" on public.event_categories;
drop policy if exists "event categories delete" on public.event_categories;

create policy "event categories select"
on public.event_categories
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = event_categories.family_id
      and fm.user_id = auth.uid()
  )
);

create policy "event categories insert"
on public.event_categories
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = event_categories.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

create policy "event categories update"
on public.event_categories
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = event_categories.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = event_categories.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

create policy "event categories delete"
on public.event_categories
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = event_categories.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

-- Categorías iniciales para familias existentes
insert into public.event_categories (family_id, name, color, sort_order)
select f.id, v.name, v.color, v.sort_order
from public.families f
cross join (
  values
    ('Trabajo', '#3B82F6', 10),
    ('Personal', '#22C55E', 20),
    ('Médico', '#EF4444', 30),
    ('Colegio', '#F59E0B', 40),
    ('Familia', '#A855F7', 50)
) as v(name, color, sort_order)
on conflict (family_id, name) do nothing;

alter table public.event_categories replica identity full;
alter table public.events replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.event_categories;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end;
$$;

do $$
begin
  begin
    alter publication supabase_realtime add table public.events;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end;
$$;
