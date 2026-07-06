import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../sales/sale_detail_screen.dart';
import '../sales/sale_repository.dart';
import 'customer_model.dart';

Future<void> showCustomerHistorySheet(BuildContext context, Customer customer) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CustomerHistorySheet(customer: customer),
  );
}

final _customerSalesProvider = FutureProvider.family((ref, String customerId) {
  return saleRepository.fetchHistory(customerId: customerId);
});

class _CustomerHistorySheet extends ConsumerWidget {
  const _CustomerHistorySheet({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(_customerSalesProvider(customer.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
              Text('Riwayat Transaksi', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              salesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('Gagal memuat: $error'),
                data: (sales) {
                  final total = sales.fold<num>(0, (sum, sale) => sum + sale.total);
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(label: 'Frekuensi Beli', value: '${sales.length}x'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(label: 'Total Belanja', value: formatRupiah(total)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: salesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (sales) {
                    if (sales.isEmpty) {
                      return const Center(child: Text('Belum pernah bertransaksi'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: sales.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return ListTile(
                          title: Text(sale.invoiceNo),
                          subtitle: Text(formatDateTime(sale.createdAt)),
                          trailing: Text(formatRupiah(sale.total)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => SaleDetailScreen(sale: sale)),
                          ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
