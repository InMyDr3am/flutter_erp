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
    final isAdmin = ref.watch(currentProfileProvider).unwrapPrevious().value?.isAdmin ?? false;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: categoriesAsync.maybeWhen(
              data: (categories) {
                final selected = ref.watch(productCategoryFilterProvider);
                return DropdownButtonFormField<String?>(
                  initialValue: selected,
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
                      ref.read(productCategoryFilterProvider.notifier).state = value,
                );
              },
              orElse: () => const SizedBox.shrink(),
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
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        isAdmin: isAdmin,
                        onTap: isAdmin
                            ? () => showProductFormDialog(context, product: product)
                            : null,
                        onDelete: () => _confirmDelete(context, ref, product),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  final Product product;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = stockStatusOf(stock: product.stock, minStock: product.minStock);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: status.color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.categoryName ?? 'Tanpa kategori',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatRupiah(product.sellPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '/ ${product.unit}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StockStatusBadge(status: status, dense: true),
                    const SizedBox(width: 8),
                    Text(
                      '${product.stock} ${product.unit} tersisa',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (isAdmin)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hapus',
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
