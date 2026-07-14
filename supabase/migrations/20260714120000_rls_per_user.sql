-- Per-user RLS for products, product_images, sales, and product-images storage.
-- Auth: Firebase Auth JWT via Supabase Third-Party Auth (auth.uid() = Firebase UID).

create or replace function public.requesting_user_id()
returns text
language sql
stable
as $$
  select nullif(auth.uid()::text, '');
$$;

revoke all on function public.requesting_user_id() from public;
grant execute on function public.requesting_user_id() to anon, authenticated;

-- Make product images private; read via signed URL from the app.
update storage.buckets
set public = false
where id = 'product-images';

-- Drop open-dev policies from the initial migration.
drop policy if exists "dev products all" on products;
drop policy if exists "dev product_images all" on product_images;
drop policy if exists "dev sales all" on sales;
drop policy if exists "dev product images read" on storage.objects;
drop policy if exists "dev product images insert" on storage.objects;
drop policy if exists "dev product images update" on storage.objects;
drop policy if exists "dev product images delete" on storage.objects;

-- products ---------------------------------------------------------------

drop policy if exists "products_select_own" on products;
create policy "products_select_own"
  on products for select
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()));

drop policy if exists "products_insert_own" on products;
create policy "products_insert_own"
  on products for insert
  to anon, authenticated
  with check (user_id = (select public.requesting_user_id()));

drop policy if exists "products_update_own" on products;
create policy "products_update_own"
  on products for update
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

drop policy if exists "products_delete_own" on products;
create policy "products_delete_own"
  on products for delete
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()));

-- product_images (ownership via parent product) --------------------------

drop policy if exists "product_images_select_own" on product_images;
create policy "product_images_select_own"
  on product_images for select
  to anon, authenticated
  using (
    exists (
      select 1
      from products p
      where p.id = product_images.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  );

drop policy if exists "product_images_insert_own" on product_images;
create policy "product_images_insert_own"
  on product_images for insert
  to anon, authenticated
  with check (
    exists (
      select 1
      from products p
      where p.id = product_images.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  );

drop policy if exists "product_images_update_own" on product_images;
create policy "product_images_update_own"
  on product_images for update
  to anon, authenticated
  using (
    exists (
      select 1
      from products p
      where p.id = product_images.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  )
  with check (
    exists (
      select 1
      from products p
      where p.id = product_images.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  );

drop policy if exists "product_images_delete_own" on product_images;
create policy "product_images_delete_own"
  on product_images for delete
  to anon, authenticated
  using (
    exists (
      select 1
      from products p
      where p.id = product_images.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  );

-- sales ------------------------------------------------------------------

drop policy if exists "sales_select_own" on sales;
create policy "sales_select_own"
  on sales for select
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()));

drop policy if exists "sales_insert_own" on sales;
create policy "sales_insert_own"
  on sales for insert
  to anon, authenticated
  with check (
    user_id = (select public.requesting_user_id())
    and exists (
      select 1
      from products p
      where p.id = sales.product_id
        and p.user_id = (select public.requesting_user_id())
    )
  );

drop policy if exists "sales_update_own" on sales;
create policy "sales_update_own"
  on sales for update
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

drop policy if exists "sales_delete_own" on sales;
create policy "sales_delete_own"
  on sales for delete
  to anon, authenticated
  using (user_id = (select public.requesting_user_id()));

-- storage: path must start with {firebaseUid}/... ------------------------

drop policy if exists "product_images_storage_select_own" on storage.objects;
create policy "product_images_storage_select_own"
  on storage.objects for select
  to anon, authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  );

drop policy if exists "product_images_storage_insert_own" on storage.objects;
create policy "product_images_storage_insert_own"
  on storage.objects for insert
  to anon, authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  );

drop policy if exists "product_images_storage_update_own" on storage.objects;
create policy "product_images_storage_update_own"
  on storage.objects for update
  to anon, authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  )
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  );

drop policy if exists "product_images_storage_delete_own" on storage.objects;
create policy "product_images_storage_delete_own"
  on storage.objects for delete
  to anon, authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  );
