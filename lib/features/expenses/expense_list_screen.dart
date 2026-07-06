import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range_filter.dart';
import '../../core/utils/formatters.dart';
import '../reports/report_export.dart';
import 'expense_form_dialog.dart';
import 'expense_model.dart';
import 'expense_provider.dart';
import 'expense_repository.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

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

    ref.read(expenseFilterProvider.notifier).state = DateRangeFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Hapus pengeluaran "${expense.category}" senilai ${formatRupiah(expense.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await expenseRepository.delete(expense.id);
      ref.invalidate(expensesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final totalAsync = ref.watch(expenseTotalProvider);
    final filter = ref.watch(expenseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        actions: [
          expensesAsync.maybeWhen(
            data: (expenses) => PopupMenuButton<String>(
              enabled: expenses.isNotEmpty,
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (value) {
                final headers = ['Tanggal', 'Kategori', 'Catatan', 'Jumlah'];
                final rows = expenses
                    .map((e) => [formatDate(e.expenseDate), e.category, e.note ?? '', e.amount])
                    .toList();
                final total = expenses.fold<num>(0, (sum, e) => sum + e.amount);

                if (value == 'excel') {
                  exportTableToExcel(
                    sheetName: 'Laporan Pengeluaran',
                    fileName: 'laporan-pengeluaran.xlsx',
                    headers: headers,
                    rows: rows,
                  );
                } else {
                  showTablePdfPreview(
                    context,
                    previewTitle: 'Laporan Pengeluaran',
                    build: () => buildTablePdf(
                      title: 'Laporan Pengeluaran',
                      range: filter.isActive ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
                      headers: headers,
                      rows: rows.map((r) => r.map((c) => c is num ? formatRupiah(c) : c.toString()).toList()).toList(),
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
        onPressed: () => showExpenseFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Pengeluaran'),
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
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat: $error')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(child: Text('Belum ada pengeluaran pada periode ini'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        title: Text(expense.category),
                        subtitle: Text(
                          [formatDate(expense.expenseDate), if (expense.note != null) expense.note!].join(' • '),
                        ),
                        trailing: Text(formatRupiah(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => showExpenseFormDialog(context, expense: expense),
                        onLongPress: () => _confirmDelete(context, ref, expense),
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
