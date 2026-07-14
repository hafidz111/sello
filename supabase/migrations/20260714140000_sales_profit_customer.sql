-- Cost basis for profit, and optional customer label on sales.

alter table products
  add column if not exists cost_price integer not null default 0
  check (cost_price >= 0);

alter table sales
  add column if not exists unit_cost integer not null default 0
  check (unit_cost >= 0);

alter table sales
  add column if not exists customer_name text;

create index if not exists sales_customer_name_idx
  on sales (user_id, customer_name);
