import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/translation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final service = TranslationService();
  tearDown(() => ApiService().setHttpClient(http.Client()));

  test('an empty translated field is a failed translation', () async {
    ApiService().setHttpClient(
      MockClient((_) async => http.Response('{"translated":"  "}', 200)),
    );
    expect(await service.translateText('Hello', 'en', 'hu'), isNull);
  });

  test(
    'malformed responses never copy provider text into diagnostics',
    () async {
      const privateText = 'unpublished question draft';
      final logs = <String>[];
      final original = debugPrint;
      addTearDown(() => debugPrint = original);
      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
      ApiService().setHttpClient(
        MockClient((_) async => http.Response(privateText, 200)),
      );

      expect(await service.translateText('Hello', 'en', 'hu'), isNull);
      expect(
        await service.translateQuestion(
          questionData: {'questionText': 'Hello'},
          from: 'en',
          to: 'hu',
        ),
        isNull,
      );
      expect(logs.join(), isNot(contains(privateText)));
    },
  );
}
