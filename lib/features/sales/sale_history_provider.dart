import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'sale_model.dart';
import 'sale_repository.dart';

class SaleHistoryFilter {
  const SaleHistoryFilter({this.from, this.to, this.customerId, this.cashierId});

  final DateTime? from;
  final DateTime? to;
  final String? customerId;
  final String? cashierId;

  SaleHistoryFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? customerId,
    String? cashierId,
    bool clear = false,
  }) {
    if (clear) return const SaleHistoryFilter();
    return SaleHistoryFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
    );
  }

  bool get isActive => from != null || to != null;
  bool get hasPeopleFilter => customerId != null || cashierId != null;
}

final saleHistoryFilterProvider = StateProvider<SaleHistoryFilter>(
  (ref) => const SaleHistoryFilter(),
);

final saleHistoryProvider = FutureProvider<List<Sale>>((ref) {
  final filter = ref.watch(saleHistoryFilterProvider);
  return saleRepository.fetchHistory(
    from: filter.from,
    to: filter.to,
    customerId: filter.customerId,
    cashierId: filter.cashierId,
  );
});

final cashiersProvider = FutureProvider<List<({String id, String fullName})>>((ref) {
  return saleRepository.fetchCashiers();
});
