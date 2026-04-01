import 'dart:async';
import 'package:flutter/widgets.dart';

/// A [Listenable] that notifies listeners when a [Stream] emits a value.
/// Used to refresh [GoRouter] when the authentication state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
