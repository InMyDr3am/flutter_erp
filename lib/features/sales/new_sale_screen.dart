import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/stock_status.dart';
import '../products/product_provider.dart';
import 'cart_provider.dart';
import 'cart_sheet.dart';

final _saleProductSearchProvider = StateProvider<String>((ref) => '');
final _saleCategoryFilterProvider = StateProvider<String?>((ref) => null);

class NewSaleScreen extends ConsumerWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final query = ref.watch(_saleProductSearchProvider).trim().toLowerCase();
    final categoryId = ref.watch(_saleCategoryFilterProvider);
    final cartCount = ref.watch(cartProvider).length;
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari barang untuk ditambahkan...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(_saleProductSearchProvider.notifier).state = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: categoriesAsync.maybeWhen(
              data: (categories) => DropdownButtonFormField<String?>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  isDense: true,
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                  for (final category in categories)
                    DropdownMenuItem(value: category.id, child: Text(category.name)),
                ],
                onChanged: (value) =>
                    ref.read(_saleCategoryFilterProvider.notifier).state = value,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat barang: $error')),
              data: (products) {
                final filtered = products.where((p) {
                  if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
                  if (categoryId != null && p.categoryId != categoryId) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Barang tidak ditemukan'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final status = stockStatusOf(stock: product.stock, minStock: product.minStock);
                    final outOfStock = product.stock <= 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '${formatRupiah(product.sellPrice)} • Stok ${product.stock} ${product.unit}',
                        ),
                        trailing: outOfStock
                            ? const Chip(label: Text('Habis'))
                            : IconButton.filled(
                                icon: const Icon(Icons.add, size: 26),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    ref.read(cartProvider.notifier).addProduct(product),
                              ),
                        leading: StockStatusBadge(status: status, dense: true),
                        onTap: outOfStock
                            ? null
                            : () => ref.read(cartProvider.notifier).addProduct(product),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => showCartSheet(context),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              cartCount == 0
                  ? 'Keranjang kosong'
                  : '$cartCount item • ${formatRupiah(cartTotal)}',
            ),
          ),
        ),
      ),
    );
  }
}
