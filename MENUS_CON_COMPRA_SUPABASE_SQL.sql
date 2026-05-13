-- Módulo nuevo: Menús con compra
-- Ejecutar en Supabase SQL Editor.

create table if not exists public.smart_menus (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  meal_type text not null default 'lunch',
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smart_menu_ingredients (
  id uuid primary key default gen_random_uuid(),
  smart_menu_id uuid not null references public.smart_menus(id) on delete cascade,
  name text not null,
  quantity text,
  unit text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.smart_daily_menus (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  menu_date date not null,
  meal_slot text not null default 'lunch',
  smart_menu_id uuid not null references public.smart_menus(id) on delete cascade,
  shopping_confirmed boolean not null default false,
  shopping_confirmed_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, menu_date, meal_slot)
);

alter table public.smart_menus enable row level security;
alter table public.smart_menu_ingredients enable row level security;
alter table public.smart_daily_menus enable row level security;

drop policy if exists "smart menus read" on public.smart_menus;
create policy "smart menus read"
on public.smart_menus
for select
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_menus.family_id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "smart menus manage" on public.smart_menus;
create policy "smart menus manage"
on public.smart_menus
for all
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_menus.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
)
with check (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_menus.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

drop policy if exists "smart ingredients read" on public.smart_menu_ingredients;
create policy "smart ingredients read"
on public.smart_menu_ingredients
for select
using (
  exists (
    select 1
    from public.smart_menus sm
    join public.family_members fm on fm.family_id = sm.family_id
    where sm.id = smart_menu_ingredients.smart_menu_id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "smart ingredients manage" on public.smart_menu_ingredients;
create policy "smart ingredients manage"
on public.smart_menu_ingredients
for all
using (
  exists (
    select 1
    from public.smart_menus sm
    join public.family_members fm on fm.family_id = sm.family_id
    where sm.id = smart_menu_ingredients.smart_menu_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
)
with check (
  exists (
    select 1
    from public.smart_menus sm
    join public.family_members fm on fm.family_id = sm.family_id
    where sm.id = smart_menu_ingredients.smart_menu_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

drop policy if exists "smart daily read" on public.smart_daily_menus;
create policy "smart daily read"
on public.smart_daily_menus
for select
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_daily_menus.family_id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "smart daily manage" on public.smart_daily_menus;
create policy "smart daily manage"
on public.smart_daily_menus
for all
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_daily_menus.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
)
with check (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = smart_daily_menus.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

-- Activa el módulo nuevo en la configuración modular, desactivado por defecto.
insert into public.family_modules (family_id, module_key, enabled, sort_order)
select f.id, 'smart_menus', false, 35
from public.families f
on conflict (family_id, module_key) do nothing;

-- Si existe seed_family_modules, la actualiza para incluir el nuevo módulo en futuras familias.
create or replace function public.seed_family_modules(p_family_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.family_modules (family_id, module_key, enabled, sort_order)
  values
    (p_family_id, 'shopping', true, 10),
    (p_family_id, 'tasks', true, 20),
    (p_family_id, 'menus', true, 30),
    (p_family_id, 'smart_menus', false, 35),
    (p_family_id, 'calendar', true, 40),
    (p_family_id, 'chat', true, 50),
    (p_family_id, 'attachments', true, 60)
  on conflict (family_id, module_key) do nothing;
end;
$$;

grant execute on function public.seed_family_modules(uuid) to authenticated;

alter table public.smart_menus replica identity full;
alter table public.smart_menu_ingredients replica identity full;
alter table public.smart_daily_menus replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.smart_menus;
  exception when duplicate_object then null; when undefined_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.smart_menu_ingredients;
  exception when duplicate_object then null; when undefined_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.smart_daily_menus;
  exception when duplicate_object then null; when undefined_object then null;
  end;
end;
$$;
