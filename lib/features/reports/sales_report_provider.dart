import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../sales/sale_history_provider.dart';
import '../sales/sale_model.dart';
import '../sales/sale_repository.dart';

final salesReportFilterProvider = StateProvider<SaleHistoryFilter>(
  (ref) => SaleHistoryFilter(
    from: DateTime.now().subtract(const Duration(days: 30)),
    to: DateTime.now(),
  ),
);

final salesReportProvider = FutureProvider<List<Sale>>((ref) {
  final filter = ref.watch(salesReportFilterProvider);
  return saleRepository.fetchHistory(
    from: filter.from,
    to: filter.to,
    customerId: filter.customerId,
    cashierId: filter.cashierId,
  );
});
