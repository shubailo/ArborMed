import 'package:arbor_med/features/quiz/widgets/questions/true_false_renderer.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/pressable_answer_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final renderer = TrueFalseRenderer();
  const question = {
    'options': [
      {'value': 'true', 'label': 'Igaz'},
      {'value': 'false', 'label': 'Hamis'},
    ],
  };

  test('boolean keys are values even when True is the first option', () {
    for (final key in [
      1,
      '1',
      true,
      ' Igaz ',
      [1],
      '[1]',
      '"true"',
    ]) {
      expect(renderer.validateAnswer('true', key, question), isTrue);
      expect(renderer.validateAnswer('false', key, question), isFalse);
    }
    for (final key in [
      0,
      '0',
      false,
      ' Hamis ',
      [0],
      '[0]',
      '"false"',
    ]) {
      expect(renderer.validateAnswer('false', key, question), isTrue);
      expect(renderer.validateAnswer('true', key, question), isFalse);
    }
  });

  test('only recognized scalar submissions and unambiguous keys can score', () {
    for (final raw in [
      null,
      '',
      'unknown',
      [1],
      {'value': true},
    ]) {
      expect(renderer.hasAnswer(raw), isFalse);
      expect(renderer.validateAnswer(raw, raw, {}), isFalse);
    }
    expect(renderer.validateAnswer('true', [1, 0], question), isFalse);
    expect(
      renderer.validateAnswer('true', [
        [1],
      ], question),
      isFalse,
    );
    expect(renderer.formatAnswer(0), 'false');
    expect(renderer.formatAnswer(' Igaz '), 'true');
  });

  testWidgets('structured statements resolve by locale with a text fallback', (
    tester,
  ) async {
    const content = {
      'statement': {'en': 'English statement', 'hu': 'Magyar állítás'},
    };
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hu'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(
                renderer.getLocalizedText(context, {
                  'content': content,
                  'text': 'Fallback',
                }),
              ),
              Text(
                renderer.getLocalizedText(context, {'text': 'Flat question'}),
              ),
              Text(
                renderer.getLocalizedText(context, {
                  'content': {
                    'statement': {'en': 'English only'},
                  },
                }),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Magyar állítás'), findsOneWidget);
    expect(find.text('Flat question'), findsOneWidget);
    expect(find.text('English only'), findsOneWidget);
  });
  testWidgets(
    'numeric keys highlight the correct button and restore the selected answer',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      for (final key in [0, 1]) {
        final selected = 1 - key;
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => ThemeService(),
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => renderer.buildAnswerInput(
                    context,
                    {'id': 7},
                    selected,
                    (_) {},
                    isChecked: true,
                    correctAnswer: key,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expectedFinder = find.byKey(ValueKey('tf_7_${key == 1}'));
        final expected = tester.widget<PressableAnswerButton>(expectedFinder);
        final chosen = tester.widget<PressableAnswerButton>(
          find.byKey(ValueKey('tf_7_${selected == 1}')),
        );
        final palette = CozyTheme.of(
          tester.element(expectedFinder),
          listen: false,
        );
        expect(expected.backgroundColor, palette.primary);
        expect(expected.isSelected, isFalse);
        expect(expected.isWrong, isFalse);
        expect(chosen.backgroundColor, palette.error);
        expect(chosen.isSelected, isTrue);
        expect(chosen.isWrong, isTrue);
      }
    },
  );
}
