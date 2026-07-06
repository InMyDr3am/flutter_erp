import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product_model.dart';
import 'product_provider.dart';
import 'product_repository.dart';

Future<void> showProductFormDialog(
  BuildContext context, {
  Product? product,
}) {
  return showDialog(
    context: context,
    builder: (context) => ProductFormDialog(product: product),
  );
}

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.product?.name ?? '');
  late final _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice.toString() ?? '');
  late final _sellPriceController =
      TextEditingController(text: widget.product?.sellPrice.toString() ?? '');
  late final _unitController =
      TextEditingController(text: widget.product?.unit ?? 'pcs');
  late final _stockController =
      TextEditingController(text: widget.product?.stock.toString() ?? '0');
  late final _minStockController =
      TextEditingController(text: widget.product?.minStock.toString() ?? '0');

  String? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final category = await productRepository.createCategory(name);
    ref.invalidate(categoriesProvider);
    setState(() => _categoryId = category.id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await productRepository.update(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          categoryId: _categoryId,
          purchasePrice: num.parse(_purchasePriceController.text),
          sellPrice: num.parse(_sellPriceController.text),
          unit: _unitController.text.trim(),
          stock: num.parse(_stockController.text),
          minStock: num.parse(_minStockController.text),
        );
      } else {
        await productRepository.create(
          name: _nameController.text.trim(),
          categoryId: _categoryId,
          purchasePrice: num.parse(_purchasePriceController.text),
          sellPrice: num.parse(_sellPriceController.text),
          unit: _unitController.text.trim(),
          stock: num.parse(_stockController.text),
          minStock: num.parse(_minStockController.text),
        );
      }

      ref.invalidate(productsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    if (num.tryParse(value) == null) return 'Harus berupa angka';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Barang' : 'Tambah Barang'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Barang'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const Text('Gagal memuat kategori'),
                  data: (categories) => Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Kategori'),
                          items: [
                            for (final c in categories)
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (value) =>
                              setState(() => _categoryId = value),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kategori baru',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addCategory,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Harga Beli'),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Harga Jual'),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Stok Saat Ini'),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Batas Minimum Stok',
                    helperText:
                        'Dipakai untuk menentukan status stok aman/menipis/kritis',
                    helperMaxLines: 2,
                  ),
                  validator: _numberValidator,
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
