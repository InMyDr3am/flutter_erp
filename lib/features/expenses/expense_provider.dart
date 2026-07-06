import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/utils/date_range_filter.dart';
import 'expense_model.dart';
import 'expense_repository.dart';

final expenseFilterProvider = StateProvider<DateRangeFilter>(
  (ref) => defaultMonthToDateFilter(),
);

final expensesProvider = FutureProvider<List<Expense>>((ref) {
  final filter = ref.watch(expenseFilterProvider);
  return expenseRepository.fetchAll(from: filter.from, to: filter.to);
});

final expenseTotalProvider = Provider<AsyncValue<num>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.whenData(
    (expenses) => expenses.fold<num>(0, (sum, e) => sum + e.amount),
  );
});
