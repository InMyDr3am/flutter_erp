-- Demo data for presentations/testing. Run after schema.sql.
-- Categories, products, and customers below have no dependency on users
-- and can be run immediately.

insert into public.categories (name) values
  ('Sembako'), ('Elektronik'), ('Alat Tulis'), ('Rumah Tangga'), ('Minuman');

insert into public.products (name, category_id, purchase_price, sell_price, unit, stock, min_stock) values
  ('Beras 5kg', (select id from public.categories where name = 'Sembako'), 55000, 65000, 'karung', 40, 10),
  ('Minyak Goreng 2L', (select id from public.categories where name = 'Sembako'), 28000, 34000, 'botol', 8, 10),
  ('Gula Pasir 1kg', (select id from public.categories where name = 'Sembako'), 12000, 15000, 'kg', 2, 15),
  ('Kabel Charger USB-C', (select id from public.categories where name = 'Elektronik'), 15000, 25000, 'pcs', 50, 10),
  ('Power Bank 10000mAh', (select id from public.categories where name = 'Elektronik'), 90000, 135000, 'pcs', 0, 5),
  ('Buku Tulis 38 Lembar', (select id from public.categories where name = 'Alat Tulis'), 3000, 4500, 'pcs', 120, 30),
  ('Pulpen Hitam', (select id from public.categories where name = 'Alat Tulis'), 1500, 2500, 'pcs', 200, 50),
  ('Sapu Ijuk', (select id from public.categories where name = 'Rumah Tangga'), 12000, 18000, 'pcs', 15, 8),
  ('Air Mineral 600ml (Dus)', (select id from public.categories where name = 'Minuman'), 32000, 40000, 'dus', 25, 10),
  ('Kopi Sachet (Renceng)', (select id from public.categories where name = 'Minuman'), 9000, 13000, 'renceng', 6, 10);

insert into public.customers (name, phone, address, notes) values
  ('Toko Barokah', '081234567801', 'Jl. Merdeka No. 12', 'Pelanggan tetap'),
  ('Warung Bu Sri', '081234567802', 'Jl. Kenanga No. 5', null),
  ('Andi Setiawan', '081234567803', null, 'Sering beli alat tulis'),
  ('CV Sumber Rejeki', '081234567804', 'Jl. Industri No. 20', 'Distributor kecil'),
  ('Rina Wulandari', '081234567805', null, null);

-- ---------------------------------------------------------------------
-- Sample sales history for the last 14 days, so the dashboard chart and
-- reports aren't empty on first demo.
--
-- Create your demo accounts first (see SETUP.md), find the kasir
-- account's id in Table Editor > profiles, and paste it below before
-- running this block.
-- ---------------------------------------------------------------------
do $$
declare
  v_cashier_id uuid := '00000000-0000-0000-0000-000000000000'; -- replace me
  v_sale_id uuid;
  v_customer_ids uuid[];
  v_product record;
  v_running_total numeric;
  v_qty numeric;
  v_subtotal numeric;
begin
  if v_cashier_id = '00000000-0000-0000-0000-000000000000' then
    raise notice 'Skipping sample sales: set v_cashier_id to a real profile id first.';
    return;
  end if;

  select array_agg(id) into v_customer_ids from public.customers;

  for d in 0..13 loop
    for t in 1..(1 + floor(random() * 3)::int) loop
      insert into public.sales (invoice_no, customer_id, cashier_id, total, created_at)
      values (
        'INV-' || to_char(nextval('public.sales_invoice_seq'), 'FM000000'),
        v_customer_ids[1 + floor(random() * array_length(v_customer_ids, 1))::int],
        v_cashier_id,
        0,
        now() - (d || ' days')::interval - (random() * interval '8 hours')
      )
      returning id into v_sale_id;

      v_running_total := 0;

      for v_product in
        select id, name, sell_price from public.products order by random() limit (1 + floor(random() * 3)::int)
      loop
        v_qty := 1 + floor(random() * 4);
        v_subtotal := v_product.sell_price * v_qty;

        insert into public.sale_items (sale_id, product_id, product_name, qty, price, subtotal)
        values (v_sale_id, v_product.id, v_product.name, v_qty, v_product.sell_price, v_subtotal);

        v_running_total := v_running_total + v_subtotal;
      end loop;

      update public.sales set total = v_running_total where id = v_sale_id;
    end loop;
  end loop;
end $$;
