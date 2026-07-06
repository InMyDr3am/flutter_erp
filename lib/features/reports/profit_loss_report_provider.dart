import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/utils/date_range_filter.dart';
import '../dashboard/dashboard_provider.dart';
import '../expenses/expense_repository.dart';
import '../restocks/restock_repository.dart';
import '../sales/sale_repository.dart';

final profitLossReportFilterProvider = StateProvider<DateRangeFilter>(
  (ref) => defaultMonthToDateFilter(),
);

final profitLossReportProvider = FutureProvider<ProfitLoss>((ref) async {
  final filter = ref.watch(profitLossReportFilterProvider);

  final (sales, expenses, restocks) = await (
    saleRepository.fetchHistory(from: filter.from, to: filter.to),
    expenseRepository.fetchAll(from: filter.from, to: filter.to),
    restockRepository.fetchAll(from: filter.from, to: filter.to),
  ).wait;

  return ProfitLoss(
    revenue: sales.fold<num>(0, (sum, s) => sum + s.total),
    expenses: expenses.fold<num>(0, (sum, e) => sum + e.amount),
    restockCost: restocks.fold<num>(0, (sum, r) => sum + r.subtotal),
  );
});
