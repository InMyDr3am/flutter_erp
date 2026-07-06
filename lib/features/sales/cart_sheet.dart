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
  String _paymentMethod = 'cash';
  final _amountPaidController = TextEditingController();

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  num? get _amountPaid => num.tryParse(_amountPaidController.text);

  Future<void> _submit() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    final total = ref.read(cartTotalProvider);
    if (_paymentMethod == 'cash' && (_amountPaid == null || _amountPaid! < total)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal diterima kurang dari total belanja')),
      );
      return;
    }

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
        paymentMethod: _paymentMethod,
        amountPaid: _paymentMethod == 'cash' ? _amountPaid : null,
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
                                _QtyField(
                                  key: ValueKey(item.product.id),
                                  qty: item.qty,
                                  onChanged: (value) => ref
                                      .read(cartProvider.notifier)
                                      .setQty(item.product.id, value),
                                ),
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
              const SizedBox(height: 12),
              Text('Metode Pembayaran', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.payments_outlined)),
                  ButtonSegment(value: 'qris', label: Text('QRIS'), icon: Icon(Icons.qr_code)),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (selection) => setState(() => _paymentMethod = selection.first),
              ),
              if (_paymentMethod == 'cash') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _amountPaidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nominal Diterima'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembalian'),
                    Text(
                      formatRupiah((_amountPaid ?? 0) - total > 0 ? (_amountPaid ?? 0) - total : 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
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

/// A tappable quantity display that turns into a direct numeric input, so
/// buying e.g. 50 units doesn't require tapping "+" fifty times.
class _QtyField extends StatefulWidget {
  const _QtyField({super.key, required this.qty, required this.onChanged});

  final num qty;
  final ValueChanged<num> onChanged;

  @override
  State<_QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<_QtyField> {
  late final _controller = TextEditingController(text: _formatQty(widget.qty));
  late final _focusNode = FocusNode()..addListener(_onFocusChange);

  String _formatQty(num qty) => qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final value = num.tryParse(_controller.text);
    if (value != null && value > 0) {
      widget.onChanged(value);
    } else {
      _controller.text = _formatQty(widget.qty);
    }
  }

  @override
  void didUpdateWidget(covariant _QtyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qty != widget.qty && !_focusNode.hasFocus) {
      _controller.text = _formatQty(widget.qty);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}
