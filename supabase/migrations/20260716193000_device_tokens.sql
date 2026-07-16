-- Token FCM per perangkat untuk push notifikasi (stok menipis, dll).

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  token text not null,
  platform text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists device_tokens_user_id_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_select_own" on public.device_tokens;
drop policy if exists "device_tokens_insert_own" on public.device_tokens;
drop policy if exists "device_tokens_update_own" on public.device_tokens;
drop policy if exists "device_tokens_delete_own" on public.device_tokens;

create policy "device_tokens_select_own"
  on public.device_tokens for select to authenticated
  using (user_id = (select public.requesting_user_id()));

create policy "device_tokens_insert_own"
  on public.device_tokens for insert to authenticated
  with check (user_id = (select public.requesting_user_id()));

create policy "device_tokens_update_own"
  on public.device_tokens for update to authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

create policy "device_tokens_delete_own"
  on public.device_tokens for delete to authenticated
  using (user_id = (select public.requesting_user_id()));

comment on table public.device_tokens is
  'FCM device tokens per Firebase UID. Siap untuk push server-side nanti.';
