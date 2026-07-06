import 'package:flutter/material.dart';

import '../../features/customers/customer_list_screen.dart';
import '../../features/expenses/expense_list_screen.dart';
import '../../features/restocks/restock_list_screen.dart';
import '../../features/sales/new_sale_screen.dart';
import '../../features/shipping/delivery_stats_screen.dart';
import '../../features/shipping/shipping_list_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Lainnya', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _MoreTile(
            icon: Icons.point_of_sale_outlined,
            title: 'Buat Transaksi',
            subtitle: 'Alur kasir — untuk uji coba tanpa ganti akun',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Transaksi Baru')),
                  body: const NewSaleScreen(),
                ),
              ),
            ),
          ),
          _MoreTile(
            icon: Icons.people_outline,
            title: 'Data Pembeli',
            subtitle: 'Kelola data pelanggan',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CustomerListScreen()),
            ),
          ),
          _MoreTile(
            icon: Icons.local_shipping_outlined,
            title: 'Monitoring Pengiriman',
            subtitle: 'Update status transaksi yang perlu dikirim',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ShippingListScreen(canAssign: true)),
            ),
          ),
          _MoreTile(
            icon: Icons.bar_chart_outlined,
            title: 'Total Pengiriman',
            subtitle: 'Jumlah pesanan yang diselesaikan tiap pegawai',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Total Pengiriman')),
                  body: const DeliveryStatsScreen(),
                ),
              ),
            ),
          ),
          _MoreTile(
            icon: Icons.add_shopping_cart_outlined,
            title: 'Belanja Bahan / Restock',
            subtitle: 'Catat pembelian stok baru',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RestockListScreen()),
            ),
          ),
          _MoreTile(
            icon: Icons.receipt_outlined,
            title: 'Pengeluaran',
            subtitle: 'Catat biaya operasional (listrik, gaji, dll)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
