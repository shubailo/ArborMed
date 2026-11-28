import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

Future<T> withSessionLock<T>(Future<T> Function() action) async {
  final navigator = window.navigator;
  if (!navigator.has('locks')) return action();

  late T result;
  Future<JSAny?> run() async {
    result = await action();
    return null;
  }

  await navigator.locks
      .request('arbormed-session-storage', (() => run().toJS).toJS)
      .toDart;
  return result;
}
