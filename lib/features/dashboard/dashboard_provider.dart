import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/config/supabase_client.dart';
import '../../core/widgets/stock_status.dart';
import '../products/product_model.dart';
import '../products/product_provider.dart';

class DailySales {
  const DailySales({required this.date, required this.total, required this.count});

  final DateTime date;
  final num total;
  final int count;
}

class TopProduct {
  const TopProduct({required this.name, required this.qtySold, required this.revenue});

  final String name;
  final num qtySold;
  final num revenue;
}

class ChartPoint {
  const ChartPoint({required this.label, required this.total});

  final String label;
  final num total;
}

enum ChartPeriod { harian, mingguan, bulanan }

final chartPeriodProvider = StateProvider<ChartPeriod>((ref) => ChartPeriod.harian);

final dailySalesProvider = FutureProvider<List<DailySales>>((ref) async {
  final rows = await supabase.from('v_daily_sales').select();
  return rows
      .map((row) => DailySales(
            date: DateTime.parse(row['sale_date'] as String),
            total: (row['total_amount'] as num?) ?? 0,
            count: (row['transaction_count'] as num?)?.toInt() ?? 0,
          ))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

final topProductsProvider = FutureProvider<List<TopProduct>>((ref) async {
  final rows = await supabase.from('v_top_products').select().order('qty_sold', ascending: false).limit(5);
  return rows
      .map((row) => TopProduct(
            name: row['product_name'] as String,
            qtySold: (row['qty_sold'] as num?) ?? 0,
            revenue: (row['revenue'] as num?) ?? 0,
          ))
      .toList();
});

class DashboardSummary {
  const DashboardSummary({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
  });

  final num todayTotal;
  final num weekTotal;
  final num monthTotal;
}

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final salesAsync = ref.watch(dailySalesProvider);

  return salesAsync.whenData((sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);

    num sumSince(DateTime start) => sales
        .where((s) => !s.date.isBefore(start))
        .fold<num>(0, (sum, s) => sum + s.total);

    final todayTotal = sales.where((s) => s.date == today).fold<num>(0, (sum, s) => sum + s.total);

    return DashboardSummary(
      todayTotal: todayTotal,
      weekTotal: sumSince(weekAgo),
      monthTotal: sumSince(monthStart),
    );
  });
});

final chartDataProvider = Provider<AsyncValue<List<ChartPoint>>>((ref) {
  final salesAsync = ref.watch(dailySalesProvider);
  final period = ref.watch(chartPeriodProvider);

  return salesAsync.whenData((sales) {
    switch (period) {
      case ChartPeriod.harian:
        return _lastNDays(sales, 14);
      case ChartPeriod.mingguan:
        return _lastNWeeks(sales, 8);
      case ChartPeriod.bulanan:
        return _lastNMonths(sales, 6);
    }
  });
});

List<ChartPoint> _lastNDays(List<DailySales> sales, int n) {
  final now = DateTime.now();
  final byDate = {for (final s in sales) s.date: s.total};
  return List.generate(n, (i) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: n - 1 - i));
    return ChartPoint(label: '${date.day}/${date.month}', total: byDate[date] ?? 0);
  });
}

List<ChartPoint> _lastNWeeks(List<DailySales> sales, int n) {
  final now = DateTime.now();
  final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
  final buckets = List.generate(n, (i) {
    final start = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day)
        .subtract(Duration(days: 7 * (n - 1 - i)));
    return start;
  });

  return buckets.map((start) {
    final end = start.add(const Duration(days: 7));
    final total = sales
        .where((s) => !s.date.isBefore(start) && s.date.isBefore(end))
        .fold<num>(0, (sum, s) => sum + s.total);
    return ChartPoint(label: '${start.day}/${start.month}', total: total);
  }).toList();
}

List<ChartPoint> _lastNMonths(List<DailySales> sales, int n) {
  final now = DateTime.now();
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  return List.generate(n, (i) {
    final monthDate = DateTime(now.year, now.month - (n - 1 - i), 1);
    final total = sales
        .where((s) => s.date.year == monthDate.year && s.date.month == monthDate.month)
        .fold<num>(0, (sum, s) => sum + s.total);
    return ChartPoint(label: monthNames[monthDate.month - 1], total: total);
  });
}

final stockAlertsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  return productsAsync.whenData((products) {
    final alerts = products
        .where((p) => stockStatusOf(stock: p.stock, minStock: p.minStock) != StockStatus.aman)
        .toList();
    alerts.sort((a, b) {
      final sa = stockStatusOf(stock: a.stock, minStock: a.minStock);
      final sb = stockStatusOf(stock: b.stock, minStock: b.minStock);
      if (sa == sb) return 0;
      return sa == StockStatus.kritis ? -1 : 1;
    });
    return alerts;
  });
});
