-- Fix: Firebase UID is text (e.g. Iy7Kxm7...), not a UUID.
-- auth.uid() casts JWT "sub" to uuid and fails with 22P02.
-- Use auth.jwt()->>'sub' instead.

create or replace function public.requesting_user_id()
returns text
language sql
stable
as $$
  select nullif(auth.jwt()->>'sub', '');
$$;

revoke all on function public.requesting_user_id() from public;
grant execute on function public.requesting_user_id() to anon, authenticated;
