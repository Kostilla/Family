-- Recomendado para que el registro automático de dispositivos funcione bien.
-- Ejecutar en Supabase SQL Editor.

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens add column if not exists platform text;
alter table public.device_tokens add column if not exists updated_at timestamptz not null default now();
alter table public.device_tokens add column if not exists created_at timestamptz not null default now();

alter table public.device_tokens enable row level security;

drop policy if exists "users can manage own device tokens" on public.device_tokens;
create policy "users can manage own device tokens"
on public.device_tokens
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create index if not exists idx_device_tokens_user_id on public.device_tokens(user_id);
create unique index if not exists idx_device_tokens_token on public.device_tokens(token);

-- Para notificar a toda una familia, el backend/edge function debe seleccionar tokens así:
-- select dt.token
-- from public.device_tokens dt
-- join public.family_members fm on fm.user_id = dt.user_id
-- where fm.family_id = '<FAMILY_ID>'
--   and dt.user_id <> '<USUARIO_QUE_DISPARA_LA_ACCION>'; -- opcional
