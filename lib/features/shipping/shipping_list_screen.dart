import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../auth/auth_provider.dart';
import '../sales/sale_detail_screen.dart';
import '../sales/sale_model.dart';
import '../sales/sale_repository.dart';
import 'shipping_provider.dart';

class ShippingListScreen extends ConsumerWidget {
  const ShippingListScreen({super.key, this.showAppBar = true, this.canAssign = false});

  /// False when embedded as a shell tab (kasir/pegawai), which already has
  /// its own app bar; true when pushed as a standalone screen (from the
  /// admin "Lainnya" menu).
  final bool showAppBar;

  /// Whether an admin/kasir "assign pegawai" control should be shown.
  final bool canAssign;

  Future<void> _editNote(BuildContext context, WidgetRef ref, Sale sale) async {
    final controller = TextEditingController(text: sale.shippingNote ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan Pengiriman'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Contoh: dikirim via kurir toko'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (note == null) return;

    try {
      await saleRepository.updateShippingStatus(
        saleId: sale.id,
        status: sale.shippingStatus,
        note: note,
      );
      ref.invalidate(shipmentsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, Sale sale, String status) async {
    try {
      await saleRepository.updateShippingStatus(
        saleId: sale.id,
        status: status,
        recordDeliverer: true,
      );
      ref.invalidate(shipmentsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
      }
    }
  }

  Future<void> _assignPegawai(BuildContext context, WidgetRef ref, Sale sale, String? pegawaiId) async {
    try {
      await saleRepository.assignPegawai(saleId: sale.id, pegawaiId: pegawaiId);
      ref.invalidate(shipmentsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menugaskan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(shipmentsProvider);
    final isAdmin = ref.watch(currentProfileProvider).unwrapPrevious().value?.isAdmin ?? false;
    final pegawaiAsync = canAssign ? ref.watch(pegawaiListProvider) : null;

    final body = shipmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Gagal memuat: $error')),
      data: (shipments) {
        if (shipments.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shipmentsProvider),
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(child: Text('Tidak ada transaksi yang perlu dikirim')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(shipmentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shipments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sale = shipments[index];
              final locked = sale.shippingStatus == 'selesai' && !isAdmin;
              final canEditThis = canAssign && !locked;

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
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => SaleDetailScreen(sale: sale)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sale.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(formatRupiah(sale.total)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 18),
                                  ],
                                ),
                              ],
                            ),
                            Text('${formatDateTime(sale.createdAt)} • ${sale.customerName ?? 'Umum'}'),
                            if (sale.shippingNote != null && sale.shippingNote!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  sale.shippingNote!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            if (sale.deliveredByName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Diantar oleh: ${sale.deliveredByName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (canEditThis && pegawaiAsync != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: pegawaiAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Gagal memuat daftar pegawai: $e'),
                            data: (pegawaiList) => DropdownButtonFormField<String?>(
                              initialValue: sale.assignedToId,
                              decoration: const InputDecoration(labelText: 'Pegawai Pengantar'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Belum ditugaskan')),
                                for (final pegawai in pegawaiList)
                                  DropdownMenuItem(value: pegawai.id, child: Text(pegawai.fullName)),
                              ],
                              onChanged: (value) => _assignPegawai(context, ref, sale, value),
                            ),
                          ),
                        )
                      else if (sale.assignedToName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Ditugaskan ke: ${sale.assignedToName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: locked
                                ? InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Status'),
                                    child: Row(
                                      children: [
                                        Text(shippingStatusLabel(sale.shippingStatus)),
                                        const SizedBox(width: 6),
                                        Icon(Icons.lock_outline,
                                            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: sale.shippingStatus,
                                    decoration: const InputDecoration(labelText: 'Status'),
                                    items: [
                                      for (final status in shippingStatusOptions)
                                        DropdownMenuItem(value: status, child: Text(shippingStatusLabel(status))),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) _updateStatus(context, ref, sale, value);
                                    },
                                  ),
                          ),
                          if (!locked)
                            IconButton(
                              tooltip: 'Catatan',
                              icon: const Icon(Icons.edit_note_outlined),
                              onPressed: () => _editNote(context, ref, sale),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (!showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Pengiriman')),
      body: body,
    );
  }
}
