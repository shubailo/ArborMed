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
    requestedBytes = withData;
    return FilePickerResult(
        [PlatformFile(name: 'example.csv', size: 1, bytes: Uint8List(1))]);
  }
}

class _Uploader extends Fake implements AdminQuestionProvider {
  final response = Completer<Map<String, dynamic>?>();
  int calls = 0;

  @override
  Future<Map<String, dynamic>?> uploadQuestionsBatch(
      List<int> bytes, String filename) {
    calls++;
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
    expect(picker.requestedBytes, isTrue);
    expect(find.text(l10n.adminUploadSuccess(2)), findsOneWidget);
    expect(find.textContaining('Row 7: invalid topic'), findsOneWidget);
    await tester.tap(find.text(l10n.done));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });
}
