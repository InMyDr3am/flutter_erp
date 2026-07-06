import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_gate.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/reports/reports_home_screen.dart';
import '../../features/sales/new_sale_screen.dart';
import '../../features/sales/sale_history_screen.dart';
import '../../features/shipping/delivery_stats_screen.dart';
import '../../features/shipping/shipping_list_screen.dart';
import 'admin_more_screen.dart';
import 'admin_shell.dart';
import 'kasir_shell.dart';
import 'pegawai_shell.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // Drive the router's refresh from the SAME Riverpod session state that
  // currentProfileProvider (and everything else) reads — not from a
  // separate raw subscription to Supabase's auth stream. Two independent
  // listeners on the same stream can fire out of order, so the redirect
  // below could briefly see a stale (e.g. signed-out) session right after
  // logging back in, defaulting to the kasir shell before the real profile
  // catches up. Routing everything through one provider removes that race.
  ref.listen(currentSessionProvider, (previous, next) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final loggedIn = ref.read(currentSessionProvider) != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/products',
              builder: (context, state) => const ProductListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/history',
              builder: (context, state) => const SaleHistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/reports',
              builder: (context, state) => const ReportsHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/more',
              builder: (context, state) => const AdminMoreScreen(),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            KasirShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kasir/sale',
              builder: (context, state) => const NewSaleScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kasir/products',
              builder: (context, state) => const ProductListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kasir/history',
              builder: (context, state) => const SaleHistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kasir/shipments',
              builder: (context, state) => const ShippingListScreen(showAppBar: false, canAssign: true),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PegawaiShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/pegawai/shipments',
              builder: (context, state) => const ShippingListScreen(showAppBar: false),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/pegawai/stats',
              builder: (context, state) => const DeliveryStatsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
