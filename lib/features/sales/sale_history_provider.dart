import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'sale_model.dart';
import 'sale_repository.dart';

class SaleHistoryFilter {
  const SaleHistoryFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  SaleHistoryFilter copyWith({DateTime? from, DateTime? to, bool clear = false}) {
    if (clear) return const SaleHistoryFilter();
    return SaleHistoryFilter(from: from ?? this.from, to: to ?? this.to);
  }

  bool get isActive => from != null || to != null;
}

final saleHistoryFilterProvider = StateProvider<SaleHistoryFilter>(
  (ref) => const SaleHistoryFilter(),
);

final saleHistoryProvider = FutureProvider<List<Sale>>((ref) {
  final filter = ref.watch(saleHistoryFilterProvider);
  return saleRepository.fetchHistory(from: filter.from, to: filter.to);
});
