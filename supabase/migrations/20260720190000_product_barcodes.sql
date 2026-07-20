-- Barcode retail (EAN/UPC) or internal Code 128 per product.

alter table products
  add column if not exists code_type text
    check (code_type is null or code_type in ('retail', 'code128'));

alter table products
  add column if not exists code_value text;

create unique index if not exists products_user_code_value_uidx
  on products (user_id, code_value)
  where code_value is not null and code_value <> '';

create index if not exists products_user_code_lookup_idx
  on products (user_id, code_value)
  where code_value is not null and code_value <> '';

comment on column products.code_type is
  'retail = barcode kemasan (EAN/UPC). code128 = kode internal toko Sello.';

comment on column products.code_value is
  'Nilai barcode yang discan kasir. Unik per user_id.';
