import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../customers/customer_picker.dart';
import 'cart_provider.dart';
import 'receipt.dart';
import 'sale_repository.dart';

Future<void> showCartSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const CartSheet(),
  );
}

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({super.key});

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  bool _submitting = false;

  Future<void> _submit() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final customer = ref.read(cartCustomerProvider);
      final needsShipping = ref.read(cartNeedsShippingProvider);
      final note = ref.read(cartShippingNoteProvider).trim();

      final saleId = await saleRepository.createSale(
        customerId: customer?.id,
        items: items,
        needsShipping: needsShipping,
        shippingNote: note.isEmpty ? null : note,
      );

      final sale = await saleRepository.fetchDetail(saleId);

      ref.read(cartProvider.notifier).clear();
      ref.read(cartCustomerProvider.notifier).state = null;
      ref.read(cartNeedsShippingProvider.notifier).state = false;
      ref.read(cartShippingNoteProvider.notifier).state = '';

      if (!mounted) return;
      Navigator.pop(context);
      await showReceiptPreview(context, sale);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Transaksi gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final customer = ref.watch(cartCustomerProvider);
    final needsShipping = ref.watch(cartNeedsShippingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Keranjang', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Keranjang masih kosong'))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text(formatRupiah(item.product.sellPrice)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .setQty(item.product.id, item.qty - 1),
                                ),
                                Text('${item.qty}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .setQty(item.product.id, item.qty + 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(customer?.name ?? 'Pembeli umum (opsional)'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showCustomerPicker(context);
                    if (picked != null) {
                      ref.read(cartCustomerProvider.notifier).state = picked;
                    }
                  },
                  child: Text(customer == null ? 'Pilih' : 'Ganti'),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: needsShipping,
                title: const Text('Perlu Pengiriman'),
                onChanged: (value) =>
                    ref.read(cartNeedsShippingProvider.notifier).state = value ?? false,
              ),
              if (needsShipping)
                TextField(
                  decoration: const InputDecoration(labelText: 'Catatan pengiriman (opsional)'),
                  onChanged: (value) =>
                      ref.read(cartShippingNoteProvider.notifier).state = value,
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (items.isEmpty || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Selesaikan Transaksi'),
              ),
            ],
          ),
        );
      },
    );
  }
}
