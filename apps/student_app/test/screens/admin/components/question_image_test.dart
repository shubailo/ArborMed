import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_editor_dialog.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/admin_question_provider_test.dart' show MockApiService, MockAuthProvider;

final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+yDp8AAAAASUVORK5CYII=');

class _Api extends MockApiService {
  int uploads = 0;
  bool rejectFile = true;
  @override
  Future<String?> uploadImageBytes(Uint8List bytes, String filename) async {
    uploads++;
    expect(filename, 'figure.png');
    expect(bytes, _png);
    return rejectFile ? null : '/uploads/figure.png';
  }
}
class _Auth extends MockAuthProvider {
  @override
  final _Api apiService = _Api();
}
class _Picker extends FilePicker {
  final choosing = Completer<void>();
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle, String? initialDirectory, FileType type = FileType.any,
    List<String>? allowedExtensions, Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false, int compressionQuality = 0, bool allowMultiple = false,
    bool withData = false, bool withReadStream = false, bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    expect(withData, isTrue);
    expect(allowedExtensions, contains('png'));
    await choosing.future;
    return FilePickerResult([PlatformFile(name:'figure.png', size:_png.length, bytes:Uint8List.fromList(_png))]);
  }
}
void main() {
  testWidgets('a chosen illustration is previewed and survives failed upload and failed question save', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final picker = _Picker();
    FilePicker.platform = picker;
    final auth = _Auth(), writes = <Map<String,dynamic>>[];
    auth.apiService.onPut = (_, data) async {
      writes.add(data);
      if (writes.length == 1) throw Exception('save temporarily unavailable');
      return {};
    };
    final q = AdminQuestion.fromJson({'id':12, 'topic_id':2, 'type':'single_choice',
       'text':'Picture?', 'question_text_hu':'Kép?', 'options':{'en':['A','B'],'hu':['A','B']},
       'correct_answer':'A', 'content':{}});
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => AdminQuestionProvider(auth)),
    ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Builder(builder: (context) =>
        Scaffold(body: TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) =>
          QuestionEditorDialog(question:q, topics: const [
            {'id':1,'name_en':'Subject','slug':'pathology','parent_id':null},
            {'id':2,'name_en':'Section','slug':'section','parent_id':1}], onSaved: () {})), child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(QuestionEditorDialog)))!;
    final attach = find.byIcon(Icons.add_photo_alternate_outlined);
    expect(attach, findsOneWidget);
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pump();
    final save = find.text(l10n.adminSaveQuestion);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: save, matching: find.byType(ElevatedButton))).onPressed, isNull);
    picker.choosing.complete();
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage), findsWidgets);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(auth.apiService.uploads, 1);
    expect(writes, isEmpty);
    expect(find.descendant(of: find.byType(QuestionEditorDialog), matching: find.text(l10n.adminEcgUploadFailed)), findsOneWidget);
    auth.apiService.rejectFile = false;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(writes.single['content']['image_url'], '/uploads/figure.png');
    expect(writes.single['explanation_en'], isEmpty);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(writes.length, 2);
    expect(writes.last['content']['image_url'], '/uploads/figure.png');
    expect(auth.apiService.uploads, 2);
    expect(find.byType(QuestionEditorDialog), findsNothing);
  });
}
