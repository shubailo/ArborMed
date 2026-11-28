Future<T> withSessionLock<T>(Future<T> Function() action) => action();
