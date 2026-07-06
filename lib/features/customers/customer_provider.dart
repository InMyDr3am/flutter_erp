import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'customer_model.dart';
import 'customer_repository.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) {
  return customerRepository.fetchAll();
});

final customerSearchProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(customersProvider);
  final query = ref.watch(customerSearchProvider).trim().toLowerCase();

  return customersAsync.whenData((customers) {
    if (query.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.phone?.contains(query) ?? false);
    }).toList();
  });
});
