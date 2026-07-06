import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_client.dart';
import 'auth_models.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session ?? supabase.auth.currentSession;
});

final currentProfileProvider = FutureProvider<AppProfile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;

  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', session.user.id)
      .maybeSingle();

  if (row == null) return null;
  return AppProfile.fromMap(row);
});

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
