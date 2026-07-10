-- Products catalog, reference images, sales, and storage bucket.

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create table if not exists products (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,
  name        text not null,
  price       integer not null default 0 check (price >= 0),
  stock       integer not null default 0 check (stock >= 0),
  created_at  timestamptz not null default now()
);

create index if not exists products_user_id_idx on products (user_id);

create table if not exists product_images (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references products(id) on delete cascade,
  storage_path  text not null,
  angle_label   text not null,
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now()
);

create index if not exists product_images_product_id_idx on product_images (product_id);

create table if not exists sales (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,
  product_id  uuid not null references products(id),
  quantity    integer not null check (quantity > 0),
  unit_price  integer not null check (unit_price >= 0),
  total       integer not null check (total >= 0),
  created_at  timestamptz not null default now()
);

create index if not exists sales_user_id_idx on sales (user_id);
create index if not exists sales_product_id_idx on sales (product_id);

alter table products enable row level security;
alter table product_images enable row level security;
alter table sales enable row level security;

drop policy if exists "dev products all" on products;
create policy "dev products all" on products for all using (true) with check (true);

drop policy if exists "dev product_images all" on product_images;
create policy "dev product_images all" on product_images for all using (true) with check (true);

drop policy if exists "dev sales all" on sales;
create policy "dev sales all" on sales for all using (true) with check (true);

drop policy if exists "dev product images read" on storage.objects;
create policy "dev product images read" on storage.objects
  for select using (bucket_id = 'product-images');

drop policy if exists "dev product images insert" on storage.objects;
create policy "dev product images insert" on storage.objects
  for insert with check (bucket_id = 'product-images');

drop policy if exists "dev product images update" on storage.objects;
create policy "dev product images update" on storage.objects
  for update using (bucket_id = 'product-images');

drop policy if exists "dev product images delete" on storage.objects;
create policy "dev product images delete" on storage.objects
  for delete using (bucket_id = 'product-images');
