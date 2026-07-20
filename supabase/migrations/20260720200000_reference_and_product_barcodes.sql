-- Global barcode reference (Excel: A item, B barcode, C flag, D alt barcode)
-- and multi-barcode per store product.

create table if not exists public.reference_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists reference_items_normalized_name_uidx
  on public.reference_items (normalized_name);

create table if not exists public.reference_barcodes (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.reference_items(id) on delete cascade,
  code_value text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  constraint reference_barcodes_code_value_nonempty check (char_length(trim(code_value)) > 0)
);

create unique index if not exists reference_barcodes_code_value_uidx
  on public.reference_barcodes (code_value);

create index if not exists reference_barcodes_item_id_idx
  on public.reference_barcodes (item_id);

create table if not exists public.product_barcodes (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  user_id text not null,
  code_value text not null,
  code_type text not null default 'retail'
    check (code_type in ('retail', 'code128')),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  constraint product_barcodes_code_value_nonempty check (char_length(trim(code_value)) > 0)
);

create unique index if not exists product_barcodes_user_code_uidx
  on public.product_barcodes (user_id, code_value);

create index if not exists product_barcodes_product_id_idx
  on public.product_barcodes (product_id);

-- Backfill existing single barcodes on products.
insert into public.product_barcodes (product_id, user_id, code_value, code_type, is_primary)
select p.id, p.user_id, p.code_value, coalesce(p.code_type, 'code128'), true
from public.products p
where p.code_value is not null
  and char_length(trim(p.code_value)) > 0
  and not exists (
    select 1
    from public.product_barcodes pb
    where pb.product_id = p.id
      and pb.code_value = p.code_value
  );

alter table public.reference_items enable row level security;
alter table public.reference_barcodes enable row level security;
alter table public.product_barcodes enable row level security;

drop policy if exists "reference_items_select_all" on public.reference_items;
create policy "reference_items_select_all"
  on public.reference_items for select
  to anon, authenticated
  using (true);

drop policy if exists "reference_items_insert_auth" on public.reference_items;
create policy "reference_items_insert_auth"
  on public.reference_items for insert
  to authenticated
  with check (true);

drop policy if exists "reference_items_update_auth" on public.reference_items;
create policy "reference_items_update_auth"
  on public.reference_items for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "reference_barcodes_select_all" on public.reference_barcodes;
create policy "reference_barcodes_select_all"
  on public.reference_barcodes for select
  to anon, authenticated
  using (true);

drop policy if exists "reference_barcodes_insert_auth" on public.reference_barcodes;
create policy "reference_barcodes_insert_auth"
  on public.reference_barcodes for insert
  to authenticated
  with check (true);

drop policy if exists "reference_barcodes_update_auth" on public.reference_barcodes;
create policy "reference_barcodes_update_auth"
  on public.reference_barcodes for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "product_barcodes_select_own" on public.product_barcodes;
create policy "product_barcodes_select_own"
  on public.product_barcodes for select
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()));

drop policy if exists "product_barcodes_insert_own" on public.product_barcodes;
create policy "product_barcodes_insert_own"
  on public.product_barcodes for insert
  to authenticated
  with check (user_id = (select public.requesting_user_id()));

drop policy if exists "product_barcodes_update_own" on public.product_barcodes;
create policy "product_barcodes_update_own"
  on public.product_barcodes for update
  to authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

drop policy if exists "product_barcodes_delete_own" on public.product_barcodes;
create policy "product_barcodes_delete_own"
  on public.product_barcodes for delete
  to authenticated
  using (user_id = (select public.requesting_user_id()));

comment on table public.reference_items is
  'Master nama produk global (impor Excel kolom A).';

comment on table public.reference_barcodes is
  'Barcode global (Excel B utama, D alternatif jika C terisi).';

comment on table public.product_barcodes is
  'Barcode per produk toko; satu produk bisa punya banyak barcode.';
