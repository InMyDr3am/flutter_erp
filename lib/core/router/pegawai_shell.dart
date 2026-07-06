import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../widgets/app_shell.dart';

const pegawaiDestinations = [
  ShellDestination(
    label: 'Pengiriman',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
  ),
  ShellDestination(
    label: 'Statistik',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
];

class PegawaiShell extends ConsumerWidget {
  const PegawaiShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).unwrapPrevious().value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profile == null || profile.isPegawai) return;
      context.go(profile.isAdmin ? '/admin/dashboard' : '/kasir/sale');
    });

    return AppShell(
      title: 'Mini ERP',
      destinations: pegawaiDestinations,
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
