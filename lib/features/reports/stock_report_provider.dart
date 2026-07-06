import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/config/supabase_client.dart';
import '../../core/utils/date_range_filter.dart';
import '../products/product_repository.dart';
import '../restocks/restock_repository.dart';

class StockReportRow {
  const StockReportRow({
    required this.productName,
    required this.unit,
    required this.masuk,
    required this.keluar,
    required this.sisa,
  });

  final String productName;
  final String unit;
  final num masuk;
  final num keluar;
  final num sisa;
}

final stockReportFilterProvider = StateProvider<DateRangeFilter>(
  (ref) => defaultMonthToDateFilter(),
);

final stockReportProvider = FutureProvider<List<StockReportRow>>((ref) async {
  final filter = ref.watch(stockReportFilterProvider);

  final (products, restocks, saleItemRows) = await (
    productRepository.fetchAll(),
    restockRepository.fetchAll(from: filter.from, to: filter.to),
    supabase.from('sale_items').select('product_id, qty, sales(created_at)'),
  ).wait;

  final masukByProduct = <String, num>{};
  for (final restock in restocks) {
    masukByProduct[restock.productId] = (masukByProduct[restock.productId] ?? 0) + restock.qty;
  }

  final keluarByProduct = <String, num>{};
  for (final row in saleItemRows) {
    final createdAtStr = (row['sales'] as Map<String, dynamic>?)?['created_at'] as String?;
    final productId = row['product_id'] as String?;
    if (createdAtStr == null || productId == null) continue;

    final createdAt = DateTime.parse(createdAtStr);
    if (filter.from != null && createdAt.isBefore(filter.from!)) continue;
    if (filter.to != null && createdAt.isAfter(filter.to!)) continue;

    keluarByProduct[productId] = (keluarByProduct[productId] ?? 0) + (row['qty'] as num);
  }

  return products
      .map((product) => StockReportRow(
            productName: product.name,
            unit: product.unit,
            masuk: masukByProduct[product.id] ?? 0,
            keluar: keluarByProduct[product.id] ?? 0,
            sisa: product.stock,
          ))
      .toList();
});
