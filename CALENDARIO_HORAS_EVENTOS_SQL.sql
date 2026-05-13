-- Calendario: soporte de hora de inicio, hora final y eventos de todo el día.
-- Ejecutar en Supabase si todavía no tienes estas columnas.

alter table public.events
  add column if not exists start_at timestamptz,
  add column if not exists end_at timestamptz,
  add column if not exists all_day boolean not null default false,
  add column if not exists notes text,
  add column if not exists category_id uuid references public.event_categories(id) on delete set null,
  add column if not exists updated_at timestamptz not null default now();

-- Rellenar horarios antiguos que solo tenían event_date.
update public.events
set
  start_at = coalesce(start_at, event_date::timestamptz + interval '10 hours'),
  end_at = coalesce(end_at, event_date::timestamptz + interval '11 hours')
where event_date is not null;

alter table public.events replica identity full;

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
