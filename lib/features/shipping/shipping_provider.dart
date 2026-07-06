import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sales/sale_model.dart';
import '../sales/sale_repository.dart';

// autoDispose so the list is re-fetched fresh every time the screen is
// opened, instead of showing a stale cached result from earlier in the
// app session (shipments are created from a completely different screen,
// so nothing here would otherwise know to invalidate the cache).
final shipmentsProvider = FutureProvider.autoDispose<List<Sale>>((ref) {
  return saleRepository.fetchShipments();
});

final pegawaiListProvider = FutureProvider.autoDispose<List<({String id, String fullName})>>((ref) {
  return saleRepository.fetchPegawai();
});

const shippingStatusOptions = ['belum_dikirim', 'dikirim', 'selesai'];

String shippingStatusLabel(String status) => switch (status) {
      'belum_dikirim' => 'Belum Dikirim',
      'dikirim' => 'Dalam Pengiriman',
      'selesai' => 'Selesai',
      _ => status,
    };
