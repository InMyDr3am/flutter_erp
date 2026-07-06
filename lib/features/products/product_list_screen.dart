import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/stock_status.dart';
import '../auth/auth_provider.dart';
import 'product_form_dialog.dart';
import 'product_model.dart';
import 'product_provider.dart';
import 'product_repository.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Hapus "${product.name}" dari daftar barang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await productRepository.delete(product.id);
      ref.invalidate(productsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => showProductFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Barang'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(productSearchProvider.notifier).state = value,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StatusFilterChip(status: null, label: 'Semua'),
                const SizedBox(width: 8),
                _StatusFilterChip(status: StockStatus.aman, label: 'Aman'),
                const SizedBox(width: 8),
                _StatusFilterChip(status: StockStatus.menipis, label: 'Menipis'),
                const SizedBox(width: 8),
                _StatusFilterChip(status: StockStatus.kritis, label: 'Kritis'),
                const SizedBox(width: 12),
                const VerticalDivider(),
                const SizedBox(width: 4),
                categoriesAsync.maybeWhen(
                  data: (categories) => Consumer(
                    builder: (context, ref, _) {
                      final selected = ref.watch(productCategoryFilterProvider);
                      return Row(
                        children: [
                          for (final category in categories) ...[
                            ChoiceChip(
                              label: Text(category.name),
                              selected: selected == category.id,
                              onSelected: (value) {
                                ref
                                    .read(productCategoryFilterProvider.notifier)
                                    .state = value ? category.id : null;
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      );
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat barang: $error')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Belum ada barang'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(productsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final status = stockStatusOf(
                        stock: product.stock,
                        minStock: product.minStock,
                      );
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        child: ListTile(
                          onTap: isAdmin
                              ? () => showProductFormDialog(context, product: product)
                              : null,
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.categoryName ?? '-'} • ${formatRupiah(product.sellPrice)} / ${product.unit}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StockStatusBadge(status: status, dense: true),
                              const SizedBox(height: 4),
                              Text('${product.stock} ${product.unit}'),
                            ],
                          ),
                          onLongPress: isAdmin
                              ? () => _confirmDelete(context, ref, product)
                              : null,
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

class _StatusFilterChip extends ConsumerWidget {
  const _StatusFilterChip({required this.status, required this.label});

  final StockStatus? status;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(productStatusFilterProvider) == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          ref.read(productStatusFilterProvider.notifier).state = status,
    );
  }
}
