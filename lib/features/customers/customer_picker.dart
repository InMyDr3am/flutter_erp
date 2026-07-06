import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_form_dialog.dart';
import 'customer_model.dart';
import 'customer_provider.dart';

/// Bottom sheet to pick an existing customer, add a new one on the fly, or
/// skip (walk-in / no customer recorded).
Future<Customer?> showCustomerPicker(BuildContext context) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CustomerPickerSheet(),
  );
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

  @override
  ConsumerState<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pilih Pembeli',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await showCustomerFormDialog(context);
                      if (created != null && context.mounted) {
                        Navigator.pop(context, created);
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Baru'),
                  ),
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama/telepon...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value.toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: customersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Gagal memuat: $e')),
                  data: (customers) {
                    final filtered = _query.isEmpty
                        ? customers
                        : customers
                            .where((c) =>
                                c.name.toLowerCase().contains(_query) ||
                                (c.phone?.contains(_query) ?? false))
                            .toList();

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(customer.name),
                          subtitle: customer.phone != null ? Text(customer.phone!) : null,
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
