import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import 'expense_model.dart';
import 'expense_provider.dart';
import 'expense_repository.dart';

Future<void> showExpenseFormDialog(BuildContext context, {Expense? expense}) {
  return showDialog(
    context: context,
    builder: (context) => ExpenseFormDialog(expense: expense),
  );
}

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _categoryController =
      TextEditingController(text: widget.expense?.category ?? '');
  late final _amountController =
      TextEditingController(text: widget.expense?.amount.toString() ?? '');
  late final _noteController = TextEditingController(text: widget.expense?.note ?? '');
  late DateTime _date = widget.expense?.expenseDate ?? DateTime.now();

  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await expenseRepository.update(
          id: widget.expense!.id,
          category: _categoryController.text.trim(),
          amount: num.parse(_amountController.text),
          expenseDate: _date,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      } else {
        await expenseRepository.create(
          category: _categoryController.text.trim(),
          amount: num.parse(_amountController.text),
          expenseDate: _date,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      }

      ref.invalidate(expensesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final suggestion in expenseCategorySuggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () => setState(() => _categoryController.text = suggestion),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                    if (num.tryParse(value) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
