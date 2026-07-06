-- Mini ERP database schema
-- Run this once in the Supabase SQL editor (Project > SQL Editor > New query).

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- Profiles (extends auth.users with app role)
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  role text not null default 'kasir' check (role in ('admin', 'kasir', 'pegawai')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.is_pegawai()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'pegawai'
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'role', 'kasir')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create policy "profiles_select" on public.profiles
  for select using (auth.uid() = id or public.is_admin() or public.is_pegawai());

create policy "profiles_update" on public.profiles
  for update using (auth.uid() = id or public.is_admin());

-- ---------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

alter table public.categories enable row level security;

create policy "categories_select" on public.categories
  for select using (auth.role() = 'authenticated');

create policy "categories_write" on public.categories
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Products (Barang)
-- ---------------------------------------------------------------------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references public.categories (id),
  purchase_price numeric(14, 2) not null default 0,
  sell_price numeric(14, 2) not null default 0,
  unit text not null default 'pcs',
  stock numeric(14, 2) not null default 0,
  min_stock numeric(14, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "products_select" on public.products
  for select using (auth.role() = 'authenticated');

create policy "products_write" on public.products
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Customers (Pembeli)
-- ---------------------------------------------------------------------
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  address text,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.customers enable row level security;

create policy "customers_select" on public.customers
  for select using (auth.role() = 'authenticated');

create policy "customers_insert" on public.customers
  for insert with check (auth.role() = 'authenticated');

create policy "customers_update_delete" on public.customers
  for update using (public.is_admin()) with check (public.is_admin());

create policy "customers_delete" on public.customers
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------
-- Sales (Transaksi) + line items
-- ---------------------------------------------------------------------
create sequence public.sales_invoice_seq start 1;

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  invoice_no text not null unique,
  customer_id uuid references public.customers (id),
  cashier_id uuid not null references public.profiles (id),
  total numeric(14, 2) not null default 0,
  payment_method text not null default 'cash' check (payment_method in ('cash', 'qris')),
  amount_paid numeric(14, 2),
  needs_shipping boolean not null default false,
  shipping_status text not null default 'tidak_perlu'
    check (shipping_status in ('tidak_perlu', 'belum_dikirim', 'dikirim', 'selesai')),
  shipping_note text,
  assigned_to uuid references public.profiles (id),
  delivered_by uuid references public.profiles (id),
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.sales enable row level security;

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  product_id uuid references public.products (id),
  product_name text not null,
  qty numeric(14, 2) not null,
  price numeric(14, 2) not null,
  subtotal numeric(14, 2) not null
);

alter table public.sale_items enable row level security;

create policy "sales_select" on public.sales
  for select using (public.is_admin() or cashier_id = auth.uid());

create policy "sales_insert" on public.sales
  for insert with check (cashier_id = auth.uid());

create policy "sales_update" on public.sales
  for update using (public.is_admin()) with check (public.is_admin());

-- Pegawai (delivery staff) only see/act on sales explicitly assigned to
-- them by an admin or kasir. Combined (OR'd) with sales_select / sales_update
-- above rather than replacing them.
create policy "sales_select_pegawai" on public.sales
  for select using (public.is_pegawai() and assigned_to = auth.uid());

-- The "shipping_status <> 'selesai'" guard is on USING (the row's current
-- state) only, never WITH CHECK — otherwise transitioning *into* 'selesai'
-- would be blocked too. Once a delivery is marked done it becomes read-only
-- for pegawai/kasir; only admin (sales_update above) can still correct it.
create policy "sales_update_pegawai" on public.sales
  for update using (public.is_pegawai() and assigned_to = auth.uid() and shipping_status <> 'selesai')
  with check (public.is_pegawai() and assigned_to = auth.uid());

-- Kasir can also update shipping status/note/assignment on sales they
-- personally rang up (still gated by needs_shipping so they can't touch
-- anything else).
create policy "sales_update_kasir_own_shipment" on public.sales
  for update using (cashier_id = auth.uid() and needs_shipping and shipping_status <> 'selesai')
  with check (cashier_id = auth.uid() and needs_shipping);

create policy "sale_items_select" on public.sale_items
  for select using (
    public.is_admin() or exists (
      select 1 from public.sales s
      where s.id = sale_items.sale_id and (
        s.cashier_id = auth.uid() or (public.is_pegawai() and s.assigned_to = auth.uid())
      )
    )
  );

-- All writes to sales/sale_items happen through create_sale() below, which
-- runs as the function owner and bypasses these policies by design.

-- ---------------------------------------------------------------------
-- create_sale: inserts a sale + its line items and decrements stock
-- atomically, so a half-saved transaction can never happen.
-- ---------------------------------------------------------------------
create or replace function public.create_sale(
  p_customer_id uuid,
  p_items jsonb,
  p_needs_shipping boolean default false,
  p_shipping_note text default null,
  p_payment_method text default 'cash',
  p_amount_paid numeric default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sale_id uuid;
  v_invoice text;
  v_total numeric := 0;
  v_item jsonb;
  v_product record;
  v_qty numeric;
  v_subtotal numeric;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang masih kosong';
  end if;

  if p_payment_method not in ('cash', 'qris') then
    raise exception 'Metode pembayaran tidak valid';
  end if;

  v_invoice := 'INV-' || to_char(nextval('public.sales_invoice_seq'), 'FM000000');

  insert into public.sales (
    invoice_no, customer_id, cashier_id, total, needs_shipping, shipping_status, shipping_note,
    payment_method, amount_paid
  )
  values (
    v_invoice, p_customer_id, auth.uid(), 0, p_needs_shipping,
    case when p_needs_shipping then 'belum_dikirim' else 'tidak_perlu' end,
    p_shipping_note, p_payment_method, p_amount_paid
  )
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select id, name, sell_price, stock into v_product
    from public.products
    where id = (v_item ->> 'product_id')::uuid
    for update;

    if not found then
      raise exception 'Produk tidak ditemukan';
    end if;

    v_qty := (v_item ->> 'qty')::numeric;

    if v_qty <= 0 then
      raise exception 'Jumlah tidak valid untuk %', v_product.name;
    end if;

    if v_product.stock < v_qty then
      raise exception 'Stok % tidak mencukupi', v_product.name;
    end if;

    v_subtotal := v_product.sell_price * v_qty;
    v_total := v_total + v_subtotal;

    insert into public.sale_items (sale_id, product_id, product_name, qty, price, subtotal)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_product.sell_price, v_subtotal);

    update public.products
    set stock = stock - v_qty, updated_at = now()
    where id = v_product.id;
  end loop;

  if p_payment_method = 'cash' and (p_amount_paid is null or p_amount_paid < v_total) then
    raise exception 'Nominal pembayaran tunai kurang dari total belanja';
  end if;

  update public.sales set total = v_total where id = v_sale_id;

  return v_sale_id;
end;
$$;

grant execute on function public.create_sale(uuid, jsonb, boolean, text, text, numeric) to authenticated;

-- ---------------------------------------------------------------------
-- Expenses (Pengeluaran) and Restocks (Belanja Bahan) — schema ready now,
-- UI ships in a later phase.
-- ---------------------------------------------------------------------
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  amount numeric(14, 2) not null,
  note text,
  expense_date date not null default current_date,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

alter table public.expenses enable row level security;

create policy "expenses_admin_only" on public.expenses
  for all using (public.is_admin()) with check (public.is_admin());

create table public.restocks (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products (id),
  qty numeric(14, 2) not null,
  purchase_price numeric(14, 2) not null,
  supplier text,
  restock_date date not null default current_date,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

alter table public.restocks enable row level security;

create policy "restocks_admin_only" on public.restocks
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Reporting views (security_invoker so RLS still applies per caller)
-- ---------------------------------------------------------------------
create view public.v_daily_sales
with (security_invoker = true) as
select
  date_trunc('day', created_at)::date as sale_date,
  count(*) as transaction_count,
  sum(total) as total_amount
from public.sales
group by 1
order by 1;

create view public.v_top_products
with (security_invoker = true) as
select
  si.product_id,
  si.product_name,
  sum(si.qty) as qty_sold,
  sum(si.subtotal) as revenue
from public.sale_items si
join public.sales s on s.id = si.sale_id
group by si.product_id, si.product_name
order by qty_sold desc;

-- Realtime (optional, used by the dashboard for live refresh)
alter publication supabase_realtime add table public.sales;
