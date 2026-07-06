import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/stock_status.dart';
import '../products/product_model.dart';
import 'dashboard_provider.dart';
import 'sales_chart.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final chartAsync = ref.watch(chartDataProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final stockAlertsAsync = ref.watch(stockAlertsProvider);
    final period = ref.watch(chartPeriodProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailySalesProvider);
        ref.invalidate(topProductsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          summaryAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Gagal memuat ringkasan: $e'),
            data: (summary) => LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _SummaryCard(label: 'Hari Ini', value: summary.todayTotal),
                  _SummaryCard(label: '7 Hari Terakhir', value: summary.weekTotal),
                  _SummaryCard(label: 'Bulan Ini', value: summary.monthTotal),
                ];
                if (isWide) {
                  return Row(
                    children: [
                      for (final card in cards) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: card)),
                    ],
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grafik Penjualan', style: Theme.of(context).textTheme.titleMedium),
              SegmentedButton<ChartPeriod>(
                segments: const [
                  ButtonSegment(value: ChartPeriod.harian, label: Text('Harian')),
                  ButtonSegment(value: ChartPeriod.mingguan, label: Text('Mingguan')),
                  ButtonSegment(value: ChartPeriod.bulanan, label: Text('Bulanan')),
                ],
                selected: {period},
                onSelectionChanged: (selection) =>
                    ref.read(chartPeriodProvider.notifier).state = selection.first,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: chartAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat grafik: $e')),
              data: (points) => SalesChart(points: points),
            ),
          ),
          const SizedBox(height: 24),
          isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TopProductsSection(async: topProductsAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _StockAlertSection(async: stockAlertsAsync)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _TopProductsSection(async: topProductsAsync),
                    const SizedBox(height: 16),
                    _StockAlertSection(async: stockAlertsAsync),
                  ],
                ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              formatRupiah(value),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.async});

  final AsyncValue<List<TopProduct>> async;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barang Terlaris', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal memuat: $e'),
              data: (products) {
                if (products.isEmpty) {
                  return const Text('Belum ada data penjualan');
                }
                return Column(
                  children: [
                    for (final p in products)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text('${p.qtySold.toStringAsFixed(0)} terjual'),
                        trailing: Text(formatRupiah(p.revenue)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StockAlertSection extends StatelessWidget {
  const _StockAlertSection({required this.async});

  final AsyncValue<List<Product>> async;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peringatan Stok', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal memuat: $e'),
              data: (products) {
                if (products.isEmpty) {
                  return const Text('Semua stok dalam kondisi aman');
                }
                return Column(
                  children: [
                    for (final p in products)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text('Stok: ${p.stock} ${p.unit}'),
                        trailing: StockStatusBadge(
                          status: stockStatusOf(stock: p.stock, minStock: p.minStock),
                          dense: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
