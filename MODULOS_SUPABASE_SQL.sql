-- Sistema modular por familia para Familia Pro
-- Ejecutar en Supabase SQL Editor.

create table if not exists public.family_modules (
  family_id uuid not null references public.families(id) on delete cascade,
  module_key text not null,
  enabled boolean not null default true,
  sort_order integer not null default 999,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (family_id, module_key)
);

alter table public.family_modules enable row level security;

drop policy if exists "family modules read" on public.family_modules;
create policy "family modules read"
on public.family_modules
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_modules.family_id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "family modules manage" on public.family_modules;
create policy "family modules manage"
on public.family_modules
for all
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_modules.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_modules.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'adult')
  )
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_family_modules_updated_at on public.family_modules;
create trigger trg_family_modules_updated_at
before update on public.family_modules
for each row execute procedure public.touch_updated_at();

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
    (p_family_id, 'calendar', true, 40),
    (p_family_id, 'chat', true, 50),
    (p_family_id, 'attachments', true, 60)
  on conflict (family_id, module_key) do nothing;
end;
$$;

grant execute on function public.seed_family_modules(uuid) to authenticated;

-- Inicializa módulos para familias ya existentes.
insert into public.family_modules (family_id, module_key, enabled, sort_order)
select f.id, module_key, enabled, sort_order
from public.families f
cross join (
  values
    ('shopping', true, 10),
    ('tasks', true, 20),
    ('menus', true, 30),
    ('calendar', true, 40),
    ('chat', true, 50),
    ('attachments', true, 60)
) as defaults(module_key, enabled, sort_order)
on conflict (family_id, module_key) do nothing;

-- Versión recomendada de create_family: crea la familia, añade owner, la activa y siembra módulos.
create or replace function public.create_family(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_family_id uuid;
begin
  insert into public.families (name, created_by)
  values (p_name, auth.uid())
  returning id into new_family_id;

  insert into public.family_members (family_id, user_id, role)
  values (new_family_id, auth.uid(), 'owner')
  on conflict do nothing;

  update public.profiles
  set current_family_id = new_family_id
  where id = auth.uid();

  perform public.seed_family_modules(new_family_id);

  return new_family_id;
end;
$$;

grant execute on function public.create_family(text) to authenticated;

-- Realtime opcional para que cambios de módulos se reflejen rápido.
alter table public.family_modules replica identity full;
do $$
begin
  begin
    alter publication supabase_realtime add table public.family_modules;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end $$;


-- Limpieza: elimina módulos antiguos que ya no forman parte de la app.
delete from public.family_modules
where module_key in ('rewards', 'reviews');
