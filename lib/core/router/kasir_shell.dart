import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../widgets/app_shell.dart';

const kasirDestinations = [
  ShellDestination(
    label: 'Transaksi',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
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
];

class KasirShell extends ConsumerWidget {
  const KasirShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      title: 'Mini ERP',
      destinations: kasirDestinations,
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
