import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range_filter.dart';
import '../../core/utils/formatters.dart';
import '../reports/report_export.dart';
import 'restock_form_dialog.dart';
import 'restock_model.dart';
import 'restock_provider.dart';
import 'restock_repository.dart';

class RestockListScreen extends ConsumerWidget {
  const RestockListScreen({super.key});

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

    ref.read(restockFilterProvider.notifier).state = DateRangeFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Restock restock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Restock'),
        content: Text(
          'Hapus catatan restock "${restock.productName}"? Stok barang tidak akan otomatis dikurangi kembali.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await restockRepository.delete(restock.id);
      ref.invalidate(restocksProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restocksAsync = ref.watch(restocksProvider);
    final totalAsync = ref.watch(restockTotalCostProvider);
    final filter = ref.watch(restockFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belanja Bahan / Restock'),
        actions: [
          restocksAsync.maybeWhen(
            data: (restocks) => PopupMenuButton<String>(
              enabled: restocks.isNotEmpty,
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (value) {
                final headers = ['Tanggal', 'Barang', 'Jumlah', 'Harga Beli', 'Supplier', 'Subtotal'];
                final rows = restocks
                    .map((r) => [
                          formatDate(r.restockDate),
                          r.productName,
                          r.qty,
                          r.purchasePrice,
                          r.supplier ?? '',
                          r.subtotal,
                        ])
                    .toList();
                final total = restocks.fold<num>(0, (sum, r) => sum + r.subtotal);

                if (value == 'excel') {
                  exportTableToExcel(
                    sheetName: 'Laporan Restock',
                    fileName: 'laporan-restock.xlsx',
                    headers: headers,
                    rows: rows,
                  );
                } else {
                  showTablePdfPreview(
                    context,
                    previewTitle: 'Laporan Belanja Bahan',
                    build: () => buildTablePdf(
                      title: 'Laporan Belanja Bahan / Restock',
                      range: filter.isActive ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
                      headers: headers,
                      rows: rows
                          .map((r) => r.map((c) => c is num ? formatRupiah(c) : c.toString()).toList())
                          .toList(),
                      footerLabel: 'Total',
                      footerValue: formatRupiah(total),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRestockFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Restock'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context, ref, filter),
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      filter.isActive
                          ? '${formatDate(filter.from!)} - ${formatDate(filter.to!)}'
                          : 'Pilih periode',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                totalAsync.maybeWhen(
                  data: (total) => Text(
                    formatRupiah(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: restocksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat: $error')),
              data: (restocks) {
                if (restocks.isEmpty) {
                  return const Center(child: Text('Belum ada restock pada periode ini'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: restocks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final restock = restocks[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        title: Text(restock.productName),
                        subtitle: Text(
                          '${formatDate(restock.restockDate)} • ${restock.qty} x ${formatRupiah(restock.purchasePrice)}'
                          '${restock.supplier != null ? ' • ${restock.supplier}' : ''}',
                        ),
                        trailing: Text(formatRupiah(restock.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onLongPress: () => _confirmDelete(context, ref, restock),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
