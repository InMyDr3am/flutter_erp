import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'receipt.dart';
import 'sale_model.dart';

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sale.invoiceNo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow(label: 'Tanggal', value: formatDateTime(sale.createdAt)),
          _InfoRow(label: 'Kasir', value: sale.cashierName ?? '-'),
          _InfoRow(label: 'Pembeli', value: sale.customerName ?? 'Umum'),
          if (sale.needsShipping)
            _InfoRow(label: 'Status Pengiriman', value: sale.shippingStatus),
          const Divider(height: 32),
          Text('Barang', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in sale.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.productName} (${item.qty} x ${formatRupiah(item.price)})'),
                  ),
                  Text(formatRupiah(item.subtotal)),
                ],
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                formatRupiah(sale.total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showReceiptPreview(context, sale),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Lihat / Cetak Struk'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
