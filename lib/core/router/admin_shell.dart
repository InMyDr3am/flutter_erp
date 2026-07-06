import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../widgets/app_shell.dart';

const adminDestinations = [
  ShellDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  ShellDestination(
    label: 'Barang',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  ShellDestination(
    label: 'Riwayat',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  ShellDestination(
    label: 'Laporan',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  ShellDestination(
    label: 'Lainnya',
    icon: Icons.more_horiz_outlined,
    selectedIcon: Icons.more_horiz,
  ),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // unwrapPrevious() avoids briefly guarding based on a stale profile
    // (e.g. a previous kasir session) while a freshly logged-in user's
    // profile is still being fetched.
    final profile = ref.watch(currentProfileProvider).unwrapPrevious().value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profile == null || profile.isAdmin) return;
      context.go(profile.isPegawai ? '/pegawai/shipments' : '/kasir/sale');
    });

    return AppShell(
      title: 'Mini ERP',
      destinations: adminDestinations,
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      actions: [
        IconButton(
          tooltip: 'Keluar',
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
      body: navigationShell,
    );
  }
}
