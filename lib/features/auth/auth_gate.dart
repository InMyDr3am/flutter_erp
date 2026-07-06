import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';

/// Landing route once a session exists. Waits for the profile (role) to
/// load, then dispatches into the matching shell.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat profil pengguna'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (profile != null && profile.isAdmin) {
            context.go('/admin/dashboard');
          } else {
            context.go('/kasir/sale');
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
