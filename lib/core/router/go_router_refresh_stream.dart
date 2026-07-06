import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] into a [Listenable] so [GoRouter] can be told to
/// re-evaluate its redirect logic whenever the stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
