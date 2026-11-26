import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_preview_card.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> preview(WidgetTester tester, String type, {
    dynamic options, dynamic key, dynamic content, String language = 'en',
  }) async {
    final q = AdminQuestion(id: 1, topicId: 1, bloomLevel: 2, text: 'Prompt',
      type: type, options: options, correctAnswer: key, content: content);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => ThemeService(), child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: QuestionPreviewCard(question: q, language: language)),
    )));
    await tester.pumpAndSettle();
  }

  testWidgets('partial translations retain all choices in authored order', (tester) async {
    for (final type in ['single_choice', 'multiple_choice']) {
      await preview(tester, type, options: {
        'en': ['First', 'Second', 'Third'], 'hu': ['Első', '', 'Harmadik'],
      }, language: 'hu');
      for (final text in ['Első', 'Second', 'Harmadik']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.getCenter(find.text('Első')).dy, lessThan(tester.getCenter(find.text('Second')).dy));
      expect(tester.getCenter(find.text('Second')).dy, lessThan(tester.getCenter(find.text('Harmadik')).dy));
    }
  });

  testWidgets('matching preview accepts stored answer-map pairs', (tester) async {
    await preview(tester, 'matching', key: {'Alpha': 'One', 'Beta': 'Two'});
    for (final term in ['Alpha', 'Beta', 'One', 'Two']) {
      expect(find.text(term), findsOneWidget);
    }
  });

  testWidgets('incomplete relation uses the same unavailable state as practice', (tester) async {
    await preview(tester, 'relation_analysis', content: {'statement1': {'en': 'First only'}});
    final labels = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(labels.quizIncompleteQuestion), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
