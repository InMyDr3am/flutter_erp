import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_gate.dart';
import '../../features/auth/login_screen.dart';
import '../../features/customers/customer_list_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/reports/sales_report_screen.dart';
import '../../features/sales/new_sale_screen.dart';
import '../../features/sales/sale_history_screen.dart';
import '../config/supabase_client.dart';
import 'admin_shell.dart';
import 'go_router_refresh_stream.dart';
import 'kasir_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
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
              path: '/admin/customers',
              builder: (context, state) => const CustomerListScreen(),
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
              builder: (context, state) => const SalesReportScreen(),
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
        ],
      ),
    ],
  );
});
