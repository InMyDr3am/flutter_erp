import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../products/product_model.dart';
import '../products/product_provider.dart';
import 'restock_provider.dart';
import 'restock_repository.dart';

Future<void> showRestockFormDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const RestockFormDialog(),
  );
}

class RestockFormDialog extends ConsumerStatefulWidget {
  const RestockFormDialog({super.key});

  @override
  ConsumerState<RestockFormDialog> createState() => _RestockFormDialogState();
}

class _RestockFormDialogState extends ConsumerState<RestockFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _supplierController = TextEditingController();
  DateTime _date = DateTime.now();
  Product? _selectedProduct;
  bool _saving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
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
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih barang terlebih dahulu')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await restockRepository.create(
        productId: _selectedProduct!.id,
        qty: num.parse(_qtyController.text),
        purchasePrice: num.parse(_priceController.text),
        restockDate: _date,
        supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
      );

      ref.invalidate(restocksProvider);
      ref.invalidate(productsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return AlertDialog(
      title: const Text('Belanja Bahan / Restock'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                productsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat barang: $e'),
                  data: (products) => Autocomplete<Product>(
                    displayStringForOption: (p) => p.name,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return products;
                      final query = textEditingValue.text.toLowerCase();
                      return products.where((p) => p.name.toLowerCase().contains(query));
                    },
                    onSelected: (product) {
                      setState(() {
                        _selectedProduct = product;
                        _priceController.text = product.purchasePrice.toString();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Cari Barang',
                          prefixIcon: Icon(Icons.search),
                        ),
                        validator: (_) => _selectedProduct == null ? 'Pilih barang' : null,
                      );
                    },
                  ),
                ),
                if (_selectedProduct != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Stok saat ini: ${_selectedProduct!.stock} ${_selectedProduct!.unit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah Beli'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                          if (num.tryParse(value) == null) return 'Harus angka';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Harga Beli'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                          if (num.tryParse(value) == null) return 'Harus angka';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supplierController,
                  decoration: const InputDecoration(labelText: 'Supplier (opsional)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
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
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
