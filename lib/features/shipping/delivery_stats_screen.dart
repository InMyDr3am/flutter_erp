import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range_filter.dart';
import '../../core/utils/formatters.dart';
import '../auth/auth_provider.dart';
import 'delivery_stats_provider.dart';

enum _Preset { hariIni, mingguIni, bulanIni, kustom }

class DeliveryStatsScreen extends ConsumerStatefulWidget {
  const DeliveryStatsScreen({super.key});

  @override
  ConsumerState<DeliveryStatsScreen> createState() => _DeliveryStatsScreenState();
}

class _DeliveryStatsScreenState extends ConsumerState<DeliveryStatsScreen> {
  _Preset _preset = _Preset.hariIni;

  void _applyPreset(_Preset preset) {
    setState(() => _preset = preset);
    final now = DateTime.now();
    switch (preset) {
      case _Preset.hariIni:
        ref.read(deliveryStatsFilterProvider.notifier).state = todayFilter();
      case _Preset.mingguIni:
        ref.read(deliveryStatsFilterProvider.notifier).state = DateRangeFilter(
          from: now.subtract(const Duration(days: 6)),
          to: now,
        );
      case _Preset.bulanIni:
        ref.read(deliveryStatsFilterProvider.notifier).state = DateRangeFilter(
          from: DateTime(now.year, now.month, 1),
          to: now,
        );
      case _Preset.kustom:
        break;
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final filter = ref.read(deliveryStatsFilterProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: filter.from ?? now, end: filter.to ?? now),
    );
    if (range == null) return;

    setState(() => _preset = _Preset.kustom);
    ref.read(deliveryStatsFilterProvider.notifier).state = DateRangeFilter(
      from: range.start,
      to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentProfileProvider).unwrapPrevious().value?.isAdmin ?? false;
    final statsAsync = ref.watch(deliveryStatsProvider);
    final filter = ref.watch(deliveryStatsFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Total Pengiriman', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Hari Ini'),
                selected: _preset == _Preset.hariIni,
                onSelected: (_) => _applyPreset(_Preset.hariIni),
              ),
              ChoiceChip(
                label: const Text('7 Hari Terakhir'),
                selected: _preset == _Preset.mingguIni,
                onSelected: (_) => _applyPreset(_Preset.mingguIni),
              ),
              ChoiceChip(
                label: const Text('Bulan Ini'),
                selected: _preset == _Preset.bulanIni,
                onSelected: (_) => _applyPreset(_Preset.bulanIni),
              ),
              OutlinedButton.icon(
                onPressed: _pickCustomRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  _preset == _Preset.kustom && filter.isActive
                      ? '${formatDate(filter.from!)} - ${formatDate(filter.to!)}'
                      : 'Pilih Tanggal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Gagal memuat: $error')),
              data: (stats) => isAdmin ? _AdminStats(stats: stats) : _PegawaiStats(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

class _PegawaiStats extends StatelessWidget {
  const _PegawaiStats({required this.stats});

  final List<DeliveryStat> stats;

  @override
  Widget build(BuildContext context) {
    final count = stats.isNotEmpty ? stats.first.count : 0;
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Pesanan Diantar'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStats extends StatelessWidget {
  const _AdminStats({required this.stats});

  final List<DeliveryStat> stats;

  @override
  Widget build(BuildContext context) {
    final grandTotal = stats.fold<int>(0, (sum, s) => sum + s.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Semua Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: stats.isEmpty
              ? const Center(child: Text('Belum ada data pegawai'))
              : ListView.separated(
                  itemCount: stats.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stat = stats[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
                        title: Text(stat.pegawaiName),
                        trailing: Text(
                          '${stat.count}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
