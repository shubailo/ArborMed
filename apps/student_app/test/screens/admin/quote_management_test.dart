import 'dart:async';

import 'package:arbor_med/features/analytics/models/quote.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/admin_quotes_screen.dart';
import 'package:arbor_med/screens/admin/components/quote_editor_dialog.dart';
import 'package:arbor_med/features/quiz/widgets/study_break_icon.dart';
import 'package:arbor_med/services/admin_content_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/admin/quote_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/admin_content_provider_test.dart'
    show MockAuthProvider, MockApiService;

void main() {
  late MockApiService api;
  late AdminContentProvider content;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    content = AdminContentProvider(auth);
  });
  Future<void> open(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminContentProvider>.value(value: content),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'failed quote list offers retry, successful retry shows the stored quote',
      (tester) async {
    api.onGet = (_) async => throw StateError('Offline');
    await open(tester, const AdminQuotesScreen());
    expect(find.text('No quotes found. Add some to start the rotation!'),
        findsNothing);
    api.onGet = (_) async => [
          {'id': 8, 'text_en': 'Recovered'}
        ];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recovered'), findsOneWidget);
    int deletes = 0;
    api.onDelete = (_) async {
      deletes++;
      throw StateError('Delete unavailable');
    };
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(find.text('Delete failed'), findsOneWidget);
    expect(find.textContaining('Recovered'), findsOneWidget);
  });
  testWidgets(
      'the learner sees the material icon selected from the admin gallery',
      (tester) async {
    await open(tester, const StudyBreakIcon(iconName: 'school'));
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
  for (final preview in [false, true]) {
    testWidgets(
        'quote icon resolves URLs and bounds image size (preview=$preview)',
        (tester) async {
      Future<Image> image(String url) async {
        await open(
            tester,
            preview
                ? QuotePreviewCard(
                    text: 'Q', author: '', title: 'T', customIconUrl: url)
                : StudyBreakIcon(iconName: 'custom', customUrl: url));
        return tester.widget<Image>(find.byType(Image));
      }

      final baseSize = preview ? 110.0 : 70.0;
      const external =
          'https://assets.example.test/icon.png?scale=1.2&bg=false';
      final absolute = await image(external);
      expect((absolute.image as NetworkImage).url, external);
      expect(absolute.width, closeTo(baseSize * 1.2, 0.01));
      for (final entry in {
        'NaN': 1.0,
        'Infinity': 1.0,
        '-1': 1.0,
        '1e200': 2.5,
        '0.01': 0.5
      }.entries) {
        final relative = '/uploads/icons/icon.png?scale=${entry.key}';
        final result = await image(relative);
        expect((result.image as NetworkImage).url,
            '${ApiService.baseUrl}$relative');
        expect(result.width, closeTo(baseSize * entry.value, 0.01));
        expect(result.height, result.width);
      }
      await open(
          tester,
          preview
              ? const QuotePreviewCard(
                  text: 'Q',
                  author: '',
                  title: 'T',
                  customIconUrl: 'file:///icon.png')
              : const StudyBreakIcon(
                  iconName: 'custom', customUrl: 'file:///icon.png'));
      expect(find.byType(Image), findsNothing);
    });
  }
  testWidgets(
      'title translation uses the server contract and leaves both quote texts intact',
      (tester) async {
    final requests = <Map<String, dynamic>>[];
    api.onPost = (_, data) async {
      requests.add(data);
      return {'translated': 'New title'};
    };
    await open(
        tester,
        QuoteEditorDialog(
            quote: Quote(
                id: 5,
                textEn: 'English body',
                textHu: 'Magyar törzs',
                titleEn: 'Old title',
                titleHu: 'Magyar cím',
                author: 'Ada')));
    await tester.tap(find.byIcon(Icons.translate).first);
    await tester.pumpAndSettle();
    expect(requests, [
      {'text': 'Magyar cím', 'from': 'hu', 'to': 'en'}
    ]);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'New title');
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        'English body');
  });
  testWidgets(
      'duplicate save is suppressed and a rejected save leaves the draft available',
      (tester) async {
    final response = Completer<dynamic>();
    int writes = 0;
    api.onPost = (_, data) {
      writes++;
      return response.future;
    };
    await open(tester, const QuoteEditorDialog());
    await tester.enterText(find.byType(TextFormField).last, 'A draft');
    final save = find.byType(ElevatedButton);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(writes, 1);
    response.completeError(StateError('Save unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save the quote.'), findsOneWidget);
    expect(find.byType(QuoteEditorDialog), findsOneWidget);
  });
}
