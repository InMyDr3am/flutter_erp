import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/widgets/stock_status.dart';
import 'product_model.dart';
import 'product_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return productRepository.fetchCategories();
});

final productsProvider = FutureProvider<List<Product>>((ref) {
  return productRepository.fetchAll();
});

final productSearchProvider = StateProvider<String>((ref) => '');
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);
final productStatusFilterProvider = StateProvider<StockStatus?>((ref) => null);

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(productSearchProvider).trim().toLowerCase();
  final categoryId = ref.watch(productCategoryFilterProvider);
  final status = ref.watch(productStatusFilterProvider);

  return productsAsync.whenData((products) {
    return products.where((p) {
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) {
        return false;
      }
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (status != null &&
          stockStatusOf(stock: p.stock, minStock: p.minStock) != status) {
        return false;
      }
      return true;
    }).toList();
  });
});
