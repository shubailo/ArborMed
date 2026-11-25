import 'dart:async';

import 'package:arbor_med/features/analytics/models/ecg_case.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/ecg_editor_dialog.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/admin_question_provider_test.dart' show MockAuthProvider, MockApiService;

void main() {
  late AdminQuestionProvider provider;
  late MockApiService api;
  Map<String, dynamic>? saved;
  const original = <String, dynamic>{
    'history': 'Initial vignette',
    'rate': {'target': 100, 'min': 95, 'max': 105},
    'conduction': {'pr_interval': 160, 'qrs_duration': 90, 'qt_interval': 400},
    'clinical_interpretation': 'Keep this explanation',
    'qrs': {'bbb': 'None', 'notes': 'Keep this field'},
    'axis': {'quadrant': 'Historical value'},
    'management': {'urgency': 'Routine', 'notes': 'Existing notes', 'extra': 6},
  };
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final auth = MockAuthProvider();
    provider = AdminQuestionProvider(auth);
    api = auth.apiService as MockApiService;
    api.onGet = (_) async => [{'id': 1, 'code': 'D1', 'name_en': 'Diagnosis', 'name_hu': 'Diagnózis'}];
    saved = null;
    api.onPut = (_, data) async { saved = data; return {'id': 88, ...data}; };
  });

  Future<AppLocalizations> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Scaffold(body: TextButton(
          onPressed: () => showDialog<void>(context: context, builder: (_) => ECGEditorDialog(
            ecgCase: ECGCase(id: 88, diagnosisId: 1, imageUrl: '/uploads/ecg/case_001.png',
              difficulty: 'intermediate', findings: original), onSaved: () {})),
          child: const Text('Open')))),
      ),
    ));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(ECGEditorDialog)))!;
  }
  Finder field(String label) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == label);

  testWidgets('an in-flight ECG save keeps its form and route locked until the response arrives', (tester) async {
    final reply = Completer<Map<String, dynamic>>();
    api.onPut = (_, data) => reply.future;
    final labels = await open(tester);
    await tester.tap(find.text(labels.adminEcgSaveCase));
    await tester.pump();
    expect(tester.widgetList<AbsorbPointer>(find.ancestor(of: field(labels.adminEcgSignalmentHistory), matching: find.byType(AbsorbPointer)))
        .any((guard) => guard.absorbing), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ECGEditorDialog), findsOneWidget);
    reply.complete({'id':88});
    await tester.pumpAndSettle();
    expect(find.byType(ECGEditorDialog), findsNothing);
  });

  testWidgets('editing only the history preserves explanations, measurements, range, and unrepresented fields', (tester) async {
    final labels = await open(tester);
    await tester.enterText(field(labels.adminEcgSignalmentHistory), 'Changed vignette');
    await tester.tap(find.text(labels.adminEcgSaveCase));
    await tester.pumpAndSettle();
    expect(saved?['findings_json'], {...original, 'history':'Changed vignette'});
    expect(saved?['difficulty'], 'intermediate');
  });
  testWidgets('the editor displays the stored legacy dropdown value', (tester) async {
    await open(tester);
    expect(find.text('Historical value').hitTestable(), findsOneWidget);
  });
  testWidgets('a nonnumeric or nonpositive heart rate cannot be sent as another value', (tester) async {
    final labels = await open(tester);
    for (final value in ['wrong', '0', '-4']) {
      await tester.enterText(field(labels.adminEcgBpm), value);
      await tester.tap(find.text(labels.adminEcgSaveCase));
      await tester.pumpAndSettle();
      expect(saved, isNull, reason: value);
    }
    await tester.enterText(field(labels.adminEcgBpm), '77');
    await tester.tap(find.text(labels.adminEcgSaveCase));
    await tester.pumpAndSettle();
    expect(saved?['findings_json']['rate'], {'target':77, 'min':77, 'max':77});
  });
  testWidgets('omitting management removes that section only', (tester) async {
    final labels = await open(tester);
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(labels.adminEcgSaveCase));
    await tester.pumpAndSettle();
    final expected = Map.of(original)..remove('management');
    expect(saved?['findings_json'], expected);
  });

  testWidgets('retrying the diagnosis library retains the draft', (tester) async {
    api.onGet = (_) async => throw StateError('diagnosis service unavailable');
    final labels = await open(tester);
    expect(find.text(labels.retry), findsOneWidget);
    await tester.enterText(field(labels.adminEcgSignalmentHistory), 'Draft');
    api.onGet = (_) async => [{'id':1,'code':'D1','name_en':'Diagnosis','name_hu':'Diagnózis'}];
    await tester.tap(find.text(labels.retry)); await tester.pumpAndSettle();
    expect(find.text(labels.retry), findsNothing);
    await tester.tap(find.text(labels.adminEcgSaveCase)); await tester.pumpAndSettle();
    expect(saved?['findings_json']['history'], 'Draft');
  });
}
