import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range_filter.dart';
import '../../core/utils/formatters.dart';
import 'profit_loss_report_provider.dart';
import 'report_export.dart';

class ProfitLossReportScreen extends ConsumerWidget {
  const ProfitLossReportScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref, DateRangeFilter filter) async {
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

    ref.read(profitLossReportFilterProvider.notifier).state = DateRangeFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plAsync = ref.watch(profitLossReportProvider);
    final filter = ref.watch(profitLossReportFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Laba-Rugi'),
        actions: [
          plAsync.maybeWhen(
            data: (pl) => PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (value) {
                final headers = ['Uraian', 'Jumlah'];
                final rows = [
                  ['Pendapatan', pl.revenue],
                  ['Pengeluaran', -pl.expenses],
                  ['Belanja Bahan', -pl.restockCost],
                  [pl.net >= 0 ? 'Laba Bersih' : 'Rugi Bersih', pl.net],
                ];

                if (value == 'excel') {
                  exportTableToExcel(
                    sheetName: 'Laporan Laba Rugi',
                    fileName: 'laporan-laba-rugi.xlsx',
                    headers: headers,
                    rows: rows,
                  );
                } else {
                  showTablePdfPreview(
                    context,
                    previewTitle: 'Laporan Laba-Rugi',
                    build: () => buildTablePdf(
                      title: 'Laporan Laba-Rugi',
                      range: filter.isActive ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
                      headers: headers,
                      rows: rows.map((r) => [r[0].toString(), formatRupiah(r[1] as num)]).toList(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                PopupMenuItem(value: 'pdf', child: Text('Cetak / PDF')),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickDateRange(context, ref, filter),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                filter.isActive
                    ? '${formatDate(filter.from!)} - ${formatDate(filter.to!)}'
                    : 'Pilih periode',
              ),
            ),
            const SizedBox(height: 24),
            plAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Gagal memuat: $error'),
              data: (pl) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(label: 'Pendapatan', value: pl.revenue),
                      _Row(label: 'Pengeluaran', value: -pl.expenses),
                      _Row(label: 'Belanja Bahan', value: -pl.restockCost),
                      const Divider(height: 24),
                      _Row(
                        label: pl.net >= 0 ? 'Laba Bersih' : 'Rugi Bersih',
                        value: pl.net,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final num value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value < 0 ? '-' : ''}${formatRupiah(value.abs())}', style: style),
        ],
      ),
    );
  }
}
