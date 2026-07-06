import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/utils/date_range_filter.dart';
import 'restock_model.dart';
import 'restock_repository.dart';

final restockFilterProvider = StateProvider<DateRangeFilter>(
  (ref) => defaultMonthToDateFilter(),
);

final restocksProvider = FutureProvider<List<Restock>>((ref) {
  final filter = ref.watch(restockFilterProvider);
  return restockRepository.fetchAll(from: filter.from, to: filter.to);
});

final restockTotalCostProvider = Provider<AsyncValue<num>>((ref) {
  final restocksAsync = ref.watch(restocksProvider);
  return restocksAsync.whenData(
    (restocks) => restocks.fold<num>(0, (sum, r) => sum + r.subtotal),
  );
});
