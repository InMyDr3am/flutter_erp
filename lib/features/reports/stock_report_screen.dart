import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range_filter.dart';
import '../../core/utils/formatters.dart';
import 'report_export.dart';
import 'stock_report_provider.dart';

class StockReportScreen extends ConsumerWidget {
  const StockReportScreen({super.key});

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

    ref.read(stockReportFilterProvider.notifier).state = DateRangeFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(stockReportProvider);
    final filter = ref.watch(stockReportFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok'),
        actions: [
          reportAsync.maybeWhen(
            data: (rows) => PopupMenuButton<String>(
              enabled: rows.isNotEmpty,
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (value) {
                final headers = ['Barang', 'Masuk', 'Keluar', 'Sisa Stok'];
                final dataRows = rows
                    .map((r) => [r.productName, r.masuk, r.keluar, '${r.sisa} ${r.unit}'])
                    .toList();

                if (value == 'excel') {
                  exportTableToExcel(
                    sheetName: 'Laporan Stok',
                    fileName: 'laporan-stok.xlsx',
                    headers: headers,
                    rows: dataRows,
                  );
                } else {
                  showTablePdfPreview(
                    context,
                    previewTitle: 'Laporan Stok',
                    build: () => buildTablePdf(
                      title: 'Laporan Stok Barang',
                      range: filter.isActive ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
                      headers: headers,
                      rows: dataRows.map((r) => r.map((c) => c.toString()).toList()).toList(),
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
            const SizedBox(height: 16),
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Gagal memuat: $error')),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Center(child: Text('Belum ada data barang'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Barang')),
                          DataColumn(label: Text('Masuk'), numeric: true),
                          DataColumn(label: Text('Keluar'), numeric: true),
                          DataColumn(label: Text('Sisa Stok'), numeric: true),
                        ],
                        rows: [
                          for (final row in rows)
                            DataRow(cells: [
                              DataCell(Text(row.productName)),
                              DataCell(Text('${row.masuk}')),
                              DataCell(Text('${row.keluar}')),
                              DataCell(Text('${row.sisa} ${row.unit}')),
                            ]),
                        ],
                      ),
                    ),
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
