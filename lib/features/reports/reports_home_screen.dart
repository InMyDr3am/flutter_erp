import 'package:flutter/material.dart';

import '../expenses/expense_list_screen.dart';
import '../restocks/restock_list_screen.dart';
import 'profit_loss_report_screen.dart';
import 'sales_report_screen.dart';
import 'stock_report_screen.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Laporan', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _ReportTile(
            icon: Icons.point_of_sale_outlined,
            title: 'Laporan Penjualan',
            subtitle: 'Per periode, per kasir, per pembeli',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SalesReportScreen()),
            ),
          ),
          _ReportTile(
            icon: Icons.inventory_2_outlined,
            title: 'Laporan Stok',
            subtitle: 'Barang masuk, keluar, dan sisa stok',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StockReportScreen()),
            ),
          ),
          _ReportTile(
            icon: Icons.add_shopping_cart_outlined,
            title: 'Laporan Belanja Bahan',
            subtitle: 'Riwayat restock per periode',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RestockListScreen()),
            ),
          ),
          _ReportTile(
            icon: Icons.receipt_outlined,
            title: 'Laporan Pengeluaran',
            subtitle: 'Biaya operasional per periode/kategori',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
            ),
          ),
          _ReportTile(
            icon: Icons.summarize_outlined,
            title: 'Laporan Laba-Rugi',
            subtitle: 'Pendapatan − Pengeluaran − Belanja Bahan',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfitLossReportScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
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
