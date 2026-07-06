import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import 'sale_detail_screen.dart';
import 'sale_history_provider.dart';

class SaleHistoryScreen extends ConsumerWidget {
  const SaleHistoryScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (range == null) return;

    ref.read(saleHistoryFilterProvider.notifier).state = SaleHistoryFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleHistoryProvider);
    final filter = ref.watch(saleHistoryFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context, ref),
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      filter.isActive
                          ? '${formatDate(filter.from!)} - ${formatDate(filter.to!)}'
                          : 'Filter tanggal',
                    ),
                  ),
                ),
                if (filter.isActive)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref.read(saleHistoryFilterProvider.notifier).state =
                        filter.copyWith(clear: true),
                  ),
              ],
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat riwayat: $error')),
              data: (sales) {
                if (sales.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(saleHistoryProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: sales.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        child: ListTile(
                          title: Text(sale.invoiceNo),
                          subtitle: Text(
                            '${formatDateTime(sale.createdAt)} • ${sale.customerName ?? 'Umum'} • ${sale.cashierName ?? '-'}',
                          ),
                          trailing: Text(
                            formatRupiah(sale.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => SaleDetailScreen(sale: sale)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
