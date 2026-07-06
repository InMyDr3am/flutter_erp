import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/config/supabase_client.dart';
import '../../core/utils/date_range_filter.dart';
import '../auth/auth_provider.dart';

class DeliveryStat {
  const DeliveryStat({required this.pegawaiId, required this.pegawaiName, required this.count});

  final String pegawaiId;
  final String pegawaiName;
  final int count;
}

final deliveryStatsFilterProvider = StateProvider<DateRangeFilter>((ref) => todayFilter());

final deliveryStatsProvider = FutureProvider.autoDispose<List<DeliveryStat>>((ref) async {
  final filter = ref.watch(deliveryStatsFilterProvider);
  final profile = await ref.watch(currentProfileProvider.future);

  final onlyPegawaiId = (profile != null && !profile.isAdmin) ? profile.id : null;

  var query = supabase
      .from('sales')
      .select('delivered_by')
      .eq('shipping_status', 'selesai')
      .not('delivered_by', 'is', null);

  if (filter.from != null) {
    query = query.gte('delivered_at', filter.from!.toIso8601String());
  }
  if (filter.to != null) {
    query = query.lte('delivered_at', filter.to!.toIso8601String());
  }
  if (onlyPegawaiId != null) {
    query = query.eq('delivered_by', onlyPegawaiId);
  }

  final (pegawaiRows, rows) = await (
    supabase.from('profiles').select('id, full_name').eq('role', 'pegawai').order('full_name'),
    query,
  ).wait;

  final counts = <String, int>{};
  for (final row in rows) {
    final id = row['delivered_by'] as String;
    counts[id] = (counts[id] ?? 0) + 1;
  }

  final relevantPegawai = onlyPegawaiId == null
      ? pegawaiRows
      : pegawaiRows.where((row) => row['id'] == onlyPegawaiId);

  final stats = relevantPegawai
      .map((row) => DeliveryStat(
            pegawaiId: row['id'] as String,
            pegawaiName: (row['full_name'] as String?) ?? '-',
            count: counts[row['id']] ?? 0,
          ))
      .toList();

  stats.sort((a, b) => b.count.compareTo(a.count));
  return stats;
});
