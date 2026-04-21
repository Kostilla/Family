-- Familia Pro · migración principal
-- Multi-familia + realtime + adjuntos + push
create extension if not exists pgcrypto;

create type family_role as enum ('owner', 'adult', 'child');
create type invite_status as enum ('pending', 'accepted', 'revoked');
create type meal_type as enum ('lunch', 'dinner');
create type notification_kind as enum ('chat', 'shopping', 'task', 'event', 'invite', 'system');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text not null default '',
  avatar_url text,
  current_family_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role family_role not null default 'adult',
  is_current boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

alter table public.profiles
  add constraint profiles_current_family_fk
  foreign key (current_family_id) references public.families(id) on delete set null;

create table if not exists public.family_invites (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  email text not null,
  role family_role not null default 'adult',
  invited_by uuid not null references public.profiles(id) on delete cascade,
  status invite_status not null default 'pending',
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);

create unique index if not exists uq_family_invites_pending
  on public.family_invites(family_id, lower(email))
  where status = 'pending';

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  label text not null,
  color text not null default '#1E88E5',
  sort_order int not null default 0,
  created_by uuid not null references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, label)
);

create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  text text not null,
  qty text,
  category text,
  is_done boolean not null default false,
  list_name text not null default 'principal',
  added_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_shopping_family_done_updated
  on public.shopping_items(family_id, is_done, updated_at desc);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  title text not null,
  notes text,
  due_at timestamptz,
  is_done boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  assigned_to uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_tasks_family_done_due
  on public.tasks(family_id, is_done, due_at asc nulls last);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  text text not null check (char_length(text) > 0),
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_family_created
  on public.chat_messages(family_id, created_at asc);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  title text not null,
  notes text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  all_day boolean not null default false,
  color text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_at >= start_at)
);

create index if not exists idx_events_family_start
  on public.events(family_id, start_at);

create table if not exists public.meal_entries (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  day_date date not null,
  meal_type meal_type not null,
  text text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(family_id, day_date, meal_type)
);

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  shopping_item_id uuid references public.shopping_items(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete cascade,
  chat_message_id uuid references public.chat_messages(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  storage_path text not null unique,
  original_name text not null,
  mime_type text,
  size_bytes bigint,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (
    ((shopping_item_id is not null)::int +
     (task_id is not null)::int +
     (chat_message_id is not null)::int +
     (event_id is not null)::int) = 1
  )
);

create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  kind notification_kind not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    lower(coalesce(new.email, '')),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(coalesce(new.email, ''), '@', 1))
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(nullif(excluded.display_name, ''), public.profiles.display_name),
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_families_updated_at on public.families;
create trigger touch_families_updated_at before update on public.families
for each row execute function public.touch_updated_at();

drop trigger if exists touch_categories_updated_at on public.categories;
create trigger touch_categories_updated_at before update on public.categories
for each row execute function public.touch_updated_at();

drop trigger if exists touch_shopping_updated_at on public.shopping_items;
create trigger touch_shopping_updated_at before update on public.shopping_items
for each row execute function public.touch_updated_at();

drop trigger if exists touch_tasks_updated_at on public.tasks;
create trigger touch_tasks_updated_at before update on public.tasks
for each row execute function public.touch_updated_at();

drop trigger if exists touch_events_updated_at on public.events;
create trigger touch_events_updated_at before update on public.events
for each row execute function public.touch_updated_at();

drop trigger if exists touch_meal_entries_updated_at on public.meal_entries;
create trigger touch_meal_entries_updated_at before update on public.meal_entries
for each row execute function public.touch_updated_at();

drop trigger if exists touch_device_tokens_updated_at on public.device_tokens;
create trigger touch_device_tokens_updated_at before update on public.device_tokens
for each row execute function public.touch_updated_at();

create or replace function public.is_family_member(p_family_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = auth.uid()
  );
$$;

create or replace function public.has_family_role(p_family_id uuid, p_roles family_role[])
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = auth.uid()
      and fm.role = any(p_roles)
  );
$$;

create or replace function public.create_family(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_family_id uuid;
  v_user uuid;
begin
  v_user := auth.uid();
  if v_user is null then
    raise exception 'auth required';
  end if;

  insert into public.families (name, created_by)
  values (trim(p_name), v_user)
  returning id into v_family_id;

  insert into public.family_members (family_id, user_id, role, is_current)
  values (v_family_id, v_user, 'owner', true);

  update public.profiles
     set current_family_id = v_family_id
   where id = v_user;

  return v_family_id;
end;
$$;

create or replace function public.set_current_family(p_family_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_family_member(p_family_id) then
    raise exception 'not a member of family';
  end if;

  update public.family_members
     set is_current = (family_id = p_family_id)
   where user_id = auth.uid();

  update public.profiles
     set current_family_id = p_family_id
   where id = auth.uid();
end;
$$;

create or replace function public.my_families()
returns table (
  family_id uuid,
  family_name text,
  role family_role,
  is_current boolean
)
language sql
security definer
set search_path = public
as $$
  select f.id, f.name, fm.role, (p.current_family_id = f.id) as is_current
  from public.family_members fm
  join public.families f on f.id = fm.family_id
  join public.profiles p on p.id = fm.user_id
  where fm.user_id = auth.uid()
  order by is_current desc, f.created_at asc;
$$;

create or replace function public.accept_pending_family_invites()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_count int := 0;
  r record;
begin
  select lower(email) into v_email from public.profiles where id = auth.uid();

  for r in
    select *
    from public.family_invites
    where lower(email) = v_email
      and status = 'pending'
  loop
    insert into public.family_members (family_id, user_id, role)
    values (r.family_id, auth.uid(), r.role)
    on conflict (family_id, user_id) do update set role = excluded.role;

    update public.family_invites
       set status = 'accepted',
           accepted_at = now()
     where id = r.id;

    v_count := v_count + 1;
  end loop;

  if (select current_family_id from public.profiles where id = auth.uid()) is null then
    update public.profiles
       set current_family_id = (
         select family_id
         from public.family_members
         where user_id = auth.uid()
         order by joined_at asc
         limit 1
       )
     where id = auth.uid();
  end if;

  return v_count;
end;
$$;

create or replace view public.chat_message_feed as
select
  m.id,
  m.family_id,
  m.text,
  m.created_by,
  coalesce(p.display_name, 'Usuario') as author_name,
  m.created_at
from public.chat_messages m
left join public.profiles p on p.id = m.created_by;

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invites enable row level security;
alter table public.categories enable row level security;
alter table public.shopping_items enable row level security;
alter table public.tasks enable row level security;
alter table public.chat_messages enable row level security;
alter table public.events enable row level security;
alter table public.meal_entries enable row level security;
alter table public.attachments enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notifications enable row level security;

create policy "profiles_self_select"
on public.profiles for select
using (id = auth.uid());

create policy "profiles_self_update"
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

create policy "families_member_select"
on public.families for select
using (public.is_family_member(id));

create policy "families_owner_or_adult_update"
on public.families for update
using (public.has_family_role(id, array['owner'::family_role, 'adult'::family_role]))
with check (public.has_family_role(id, array['owner'::family_role, 'adult'::family_role]));

create policy "family_members_member_select"
on public.family_members for select
using (public.is_family_member(family_id));

create policy "family_members_owner_or_adult_insert"
on public.family_members for insert
with check (public.has_family_role(family_id, array['owner'::family_role, 'adult'::family_role]));

create policy "family_invites_select"
on public.family_invites for select
using (
  public.is_family_member(family_id)
  or lower(email) = lower((select email from public.profiles where id = auth.uid()))
);

create policy "family_invites_insert"
on public.family_invites for insert
with check (public.has_family_role(family_id, array['owner'::family_role, 'adult'::family_role]));

create policy "family_invites_update"
on public.family_invites for update
using (public.has_family_role(family_id, array['owner'::family_role, 'adult'::family_role]));

create policy "categories_member_rw"
on public.categories for all
using (public.is_family_member(family_id))
with check (public.has_family_role(family_id, array['owner'::family_role, 'adult'::family_role]));

create policy "shopping_member_rw"
on public.shopping_items for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

create policy "tasks_member_rw"
on public.tasks for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

create policy "chat_member_rw"
on public.chat_messages for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id) and created_by = auth.uid());

create policy "events_member_rw"
on public.events for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

create policy "meal_member_rw"
on public.meal_entries for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

create policy "attachments_member_rw"
on public.attachments for all
using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

create policy "device_tokens_own_rw"
on public.device_tokens for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "notifications_member_select"
on public.notifications for select
using (public.is_family_member(family_id) and (user_id is null or user_id = auth.uid()));

create policy "notifications_member_update"
on public.notifications for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Storage policies (bucket family-files)
insert into storage.buckets (id, name, public)
values ('family-files', 'family-files', false)
on conflict (id) do nothing;

create policy "family storage read"
on storage.objects for select
using (
  bucket_id = 'family-files'
  and public.is_family_member((storage.foldername(name))[1]::uuid)
);

create policy "family storage insert"
on storage.objects for insert
with check (
  bucket_id = 'family-files'
  and public.is_family_member((storage.foldername(name))[1]::uuid)
);

create policy "family storage delete"
on storage.objects for delete
using (
  bucket_id = 'family-files'
  and public.is_family_member((storage.foldername(name))[1]::uuid)
);

grant usage on schema public to anon, authenticated;
grant select on public.chat_message_feed to authenticated;
grant execute on function public.create_family(text) to authenticated;
grant execute on function public.set_current_family(uuid) to authenticated;
grant execute on function public.my_families() to authenticated;
grant execute on function public.accept_pending_family_invites() to authenticated;

-- Sugerencia:
-- alterar publication supabase_realtime add table public.chat_messages, public.shopping_items, public.tasks, public.events, public.meal_entries, public.notifications;
