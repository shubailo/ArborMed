import 'dart:async';
import 'dart:typed_data';

import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/batch_upload_dialog.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Picker extends FilePicker {
  bool requestedBytes = false;
  bool streamRequested = false;
  int calls = 0;
  Future<FilePickerResult?> Function()? pick;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    requestedBytes = withData;
    streamRequested = withReadStream;
    if (pick != null) return pick!();
    return FilePickerResult(
        [PlatformFile(name: 'example.csv', size: 1, bytes: Uint8List(1))]);
  }
}

class _Uploader extends Fake implements AdminQuestionProvider {
  final response = Completer<Map<String, dynamic>?>();
  List<int>? uploadedBytes;
  int revision = 0;
  @override
  (int, int) get actionSession => (revision, 0);
  int calls = 0;

  @override
  Future<Map<String, dynamic>?> uploadQuestionsBatch(
      List<int> bytes, String filename) {
    calls++;
    uploadedBytes = bytes;
    return calls == 1
        ? response.future
        : Completer<Map<String, dynamic>?>().future;
  }
}

void main() {
  testWidgets(
      'a picked workbook uploads once and displays the committed count and row errors',
      (tester) async {
    final picker = _Picker();
    FilePicker.platform = picker;
    final uploader = _Uploader();
    int refreshes = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => BatchUploadDialog.show(context,
                    questionProvider: uploader, onComplete: () => refreshes++),
                child: const Text('Import'),
              ))),
    ));
    final l10n = AppLocalizations.of(tester.element(find.text('Import')))!;
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.adminChooseFile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(uploader.calls, 1);
    uploader.response.complete({
      'imported': 2,
      'errors': ['Row 7: invalid topic']
    });
    await tester.pumpAndSettle();
    expect(uploader.calls, 1);
    expect(picker.requestedBytes, isFalse);
    expect(picker.streamRequested, isTrue);
    expect(find.text(l10n.adminUploadSuccess(2)), findsOneWidget);
    expect(find.textContaining('Row 7: invalid topic'), findsOneWidget);
    await tester.tap(find.text(l10n.done));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });
  Future<AppLocalizations> launch(WidgetTester t, _Picker picker,
      _Uploader uploader, VoidCallback refreshed) async {
    FilePicker.platform = picker;
    await t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('hu'),
        home: Scaffold(
            body: Builder(
                builder: (ctx) => TextButton(
                    onPressed: () => BatchUploadDialog.show(ctx,
                        questionProvider: uploader, onComplete: refreshed),
                    child: const Text('Upload'))))));
    final press = t
        .widget<TextButton>(find.widgetWithText(TextButton, 'Upload'))
        .onPressed!;
    press();
    press();
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    return AppLocalizations.of(t.element(find.byType(AlertDialog)))!;
  }

  testWidgets(
      'cancelling, unreadable and oversized files keep the picker usable without a POST',
      (t) async {
    final p = _Picker(), u = _Uploader();
    final l = await launch(t, p, u, () {});
    p.pick = () async => null;
    await t.tap(find.text(l.adminChooseFile));
    await t.pumpAndSettle();
    p.pick = () async => throw StateError('unavailable picker');
    await t.tap(find.text(l.adminChooseFile));
    await t.pumpAndSettle();
    expect(find.text(l.adminErrorReadBytes), findsOneWidget);
    p.pick = () async => FilePickerResult(
        [PlatformFile(name: 'large.csv', size: 5 * 1024 * 1024 + 1)]);
    await t.tap(find.text(l.adminChooseFile));
    await t.pumpAndSettle();
    expect(find.text(l.adminImportFileTooLarge), findsOneWidget);
    expect(u.calls, 0);
    expect(p.calls, 3);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'one streamed file gives all partial errors and refreshes before dismissing the receipt',
      (t) async {
    final p = _Picker(), u = _Uploader();
    int refresh = 0;
    final l = await launch(t, p, u, () => refresh++);
    final choose = t
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, l.adminChooseFile))
        .onPressed!;
    final pick = Completer<FilePickerResult?>();
    p.pick = () => pick.future;
    choose();
    choose();
    expect(p.calls, 1);
    pick.complete(FilePickerResult([
      PlatformFile(
        name: 'import.csv',
        size: 2,
        readStream: Stream.fromIterable([
          Uint8List.fromList([1]),
          Uint8List.fromList([2])
        ]),
      )
    ]));
    // Pump Flutter frames and give the browser's stream callbacks a turn.
    Future<void> waitFor(bool Function() ready) async {
      for (int i = 0; i < 40 && !ready(); i++) {
        await t.pump(const Duration(milliseconds: 16));
        if (!ready()) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
        }
      }
      expect(ready(), isTrue);
    }

    await waitFor(() => u.calls == 1);
    expect(u.uploadedBytes, [1, 2]);
    u.response.complete({
      'imported': '1',
      'errors': ['Row 2', 'Row 3', 'Row 4', 'Row 5']
    });
    await waitFor(() => refresh == 1);
    await t.pumpAndSettle();
    expect(find.text(l.adminImportWithErrors), findsOneWidget);
    expect(find.textContaining('Row 5'), findsOneWidget);
    expect(refresh, 1,
        reason: 'one committed result must refresh the table once');
    await t.tap(find.text(l.done));
    await t.pumpAndSettle();
    expect(refresh, 1,
        reason: 'one committed result must refresh the table once');
  });
  testWidgets(
      'a picker returning after the session changes cannot upload the selected file',
      (t) async {
    final p = _Picker(), u = _Uploader();
    final l = await launch(t, p, u, () {});
    final waiting = Completer<FilePickerResult?>();
    p.pick = () => waiting.future;
    await t.tap(find.text(l.adminChooseFile));
    await t.pump();
    u.revision++;
    waiting.complete(FilePickerResult(
        [PlatformFile(name: 'input.csv', size: 1, bytes: Uint8List(1))]));
    await t.pumpAndSettle();
    expect(u.calls, 0);
    expect(t.takeException(), isNull);
  });
}
