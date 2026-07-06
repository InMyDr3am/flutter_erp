import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_form_dialog.dart';
import 'customer_history_sheet.dart';
import 'customer_model.dart';
import 'customer_provider.dart';
import 'customer_repository.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pembeli'),
        content: Text('Hapus "${customer.name}" dari daftar pembeli?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await customerRepository.delete(customer.id);
      ref.invalidate(customersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomerFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Pembeli'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama/telepon...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(customerSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat pembeli: $error')),
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(child: Text('Belum ada pembeli'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(customersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(customer.name),
                          subtitle: Text([
                            if (customer.phone != null) customer.phone!,
                            if (customer.address != null) customer.address!,
                          ].join(' • ')),
                          trailing: IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => showCustomerFormDialog(context, customer: customer),
                          ),
                          onTap: () => showCustomerHistorySheet(context, customer),
                          onLongPress: () => _confirmDelete(context, ref, customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
