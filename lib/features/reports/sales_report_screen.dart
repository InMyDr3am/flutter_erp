import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../sales/sale_history_provider.dart';
import 'excel_export.dart';
import 'sales_report_pdf.dart';
import 'sales_report_provider.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref, SaleHistoryFilter filter) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: filter.from ?? now.subtract(const Duration(days: 30)),
        end: filter.to ?? now,
      ),
    );
    if (range == null) return;

    ref.read(salesReportFilterProvider.notifier).state = SaleHistoryFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesReportProvider);
    final filter = ref.watch(salesReportFilterProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Laporan Penjualan', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDateRange(context, ref, filter),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    filter.from != null && filter.to != null
                        ? '${formatDate(filter.from!)} - ${formatDate(filter.to!)}'
                        : 'Pilih periode',
                  ),
                ),
                salesAsync.maybeWhen(
                  data: (sales) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: sales.isEmpty ? null : () => exportSalesToExcel(sales),
                        icon: const Icon(Icons.grid_on_outlined),
                        label: const Text('Export Excel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: sales.isEmpty
                            ? null
                            : () => showSalesReportPdfPreview(
                                  context,
                                  sales,
                                  range: filter.from != null && filter.to != null
                                      ? DateTimeRange(start: filter.from!, end: filter.to!)
                                      : null,
                                ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Cetak / PDF'),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: salesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Gagal memuat laporan: $error')),
                data: (sales) {
                  if (sales.isEmpty) {
                    return const Center(child: Text('Tidak ada transaksi pada periode ini'));
                  }

                  final total = sales.fold<num>(0, (sum, sale) => sum + sale.total);

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Invoice')),
                              DataColumn(label: Text('Tanggal')),
                              DataColumn(label: Text('Pembeli')),
                              DataColumn(label: Text('Kasir')),
                              DataColumn(label: Text('Total'), numeric: true),
                            ],
                            rows: [
                              for (final sale in sales)
                                DataRow(cells: [
                                  DataCell(Text(sale.invoiceNo)),
                                  DataCell(Text(formatDateTime(sale.createdAt))),
                                  DataCell(Text(sale.customerName ?? 'Umum')),
                                  DataCell(Text(sale.cashierName ?? '-')),
                                  DataCell(Text(formatRupiah(sale.total))),
                                ]),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${sales.length} transaksi', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            'Total: ${formatRupiah(total)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
