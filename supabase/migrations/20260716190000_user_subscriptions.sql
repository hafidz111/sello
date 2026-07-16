-- Paket langganan per user (Gratis / Pro). Sumber kebenaran production.
-- user_id = Firebase UID (sama seperti products / sales).

create table if not exists public.user_subscriptions (
  user_id text primary key,
  plan text not null default 'free'
    check (plan in ('free', 'pro')),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists user_subscriptions_plan_idx
  on public.user_subscriptions (plan);

alter table public.user_subscriptions enable row level security;

drop policy if exists "user_subscriptions_select_own" on public.user_subscriptions;
drop policy if exists "user_subscriptions_insert_own" on public.user_subscriptions;
drop policy if exists "user_subscriptions_update_own" on public.user_subscriptions;

create policy "user_subscriptions_select_own"
  on public.user_subscriptions
  for select
  to authenticated
  using (user_id = (select public.requesting_user_id()));

create policy "user_subscriptions_insert_own"
  on public.user_subscriptions
  for insert
  to authenticated
  with check (user_id = (select public.requesting_user_id()));

create policy "user_subscriptions_update_own"
  on public.user_subscriptions
  for update
  to authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

comment on table public.user_subscriptions is
  'Paket Sello per Firebase UID: free | pro. Debug production: update plan di Table Editor / SQL.';
