import 'dart:async';

import 'package:arbor_med/services/admin_content_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_content_provider_test.dart' show MockApiService, MockAuthProvider;

void main() {
  late MockApiService api;
  late AdminContentProvider provider;

  setUp(() {
    final auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    provider = AdminContentProvider(auth);
  });

  test('reset discards pending quote and icon reads', () async {
    final quote = Completer<dynamic>();
    final icons = Completer<dynamic>();
    api.onGet = (path) => path.contains('folder=icons') ? icons.future : quote.future;
    final reads = [provider.fetchCurrentQuote(), provider.fetchUploadedIcons()];
    provider.resetState();
    quote.complete({'id': 1, 'text_en': 'Old account'});
    icons.complete({'images': ['/uploads/icons/old.png']});
    await Future.wait(reads);
    expect(provider.currentQuote, isNull);
    expect(provider.uploadedIcons, isEmpty);
  });

  test('deleting one icon keeps its namesake and ignores an older list', () async {
    const stored = '/uploads/stored/icons/star.png';
    const local = '/uploads/icons/star.png';
    const suffix = '/uploads/icons/superstar.png';
    final images = {'images': [local, stored, suffix]};
    api.onGet = (_) async => images;
    await provider.fetchUploadedIcons();
    final old = Completer<dynamic>();
    api.onGet = (_) => old.future;
    final read = provider.fetchUploadedIcons();
    api.onDelete = (_) async => {};
    expect(await provider.deleteUploadedIcon(stored), isTrue);
    expect(provider.uploadedIcons, [local, suffix]);
    old.complete(images);
    await read;
    expect(provider.uploadedIcons, [local, suffix]);
  });
}
