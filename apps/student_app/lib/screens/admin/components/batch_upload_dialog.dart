import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import '../../../services/admin_question_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'admin_question_action.dart';

class BatchUploadDialog {
  static Future<void> show(BuildContext context,
          {required AdminQuestionProvider questionProvider,
          required VoidCallback onComplete}) =>
      runQuestionAction(context, questionProvider, (active) async {
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ImportDialog(
                provider: questionProvider,
                active: active,
                onComplete: onComplete));
      });
}

class _ImportDialog extends StatefulWidget {
  final AdminQuestionProvider provider;
  final bool Function() active;
  final VoidCallback onComplete;
  const _ImportDialog(
      {required this.provider, required this.active, required this.onComplete});
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  static const maxBytes = 5 * 1024 * 1024;
  bool _busy = false, _uploading = false, _done = false;
  String _filename = '', _error = '';
  List<String> _errors = const [];
  int? _count;
  bool get _current =>
      mounted && widget.active() && ModalRoute.of(context)?.isCurrent == true;

  Future<void> _download() async {
    if (_busy || !_current) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await widget.provider.downloadQuestionsTemplate();
    } catch (e) {
      if (_current) {
        setState(
            () => _error = e is ApiException ? e.message : l.adminExportFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    if (_busy || !_current) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'csv'],
          withData: false,
          withReadStream: true);
      if (!_current || result == null) return;
      if (result.files.length != 1) {
        throw FormatException(l.adminErrorReadBytes);
      }
      final file = result.files.single;
      if (file.size > maxBytes) {
        throw FormatException(l.adminImportFileTooLarge);
      }
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.readStream != null) {
        final collected = await file.readStream!
            .takeWhile((_) => _current)
            .fold<BytesBuilder>(BytesBuilder(copy: false), (buffer, chunk) {
          if (buffer.length + chunk.length > maxBytes) {
            throw FormatException(l.adminImportFileTooLarge);
          }
          buffer.add(chunk);
          return buffer;
        });
        bytes = collected.takeBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        throw FormatException(l.adminErrorReadBytes);
      }
      if (bytes.length > maxBytes) {
        throw FormatException(l.adminImportFileTooLarge);
      }
      if (!_current) return;
      setState(() {
        _uploading = true;
        _filename = file.name;
      });
      final data = await widget.provider.uploadQuestionsBatch(bytes, file.name);
      if (!_current) return;
      final raw = data?['imported'];
      final count = raw == null
          ? int.tryParse(RegExp(r'^Successfully processed (\d+) questions$')
                  .firstMatch(data?['message']?.toString() ?? '')
                  ?.group(1) ??
              '')
          : int.tryParse(raw.toString());
      if (count == null || count < 0) {
        throw FormatException(l.adminUploadFailed);
      }
      final errors = data?['errors'];
      setState(() {
        _count = count;
        _errors =
            errors is List ? errors.whereType<String>().toList() : const [];
        _done = true;
      });
      if (count > 0) widget.onComplete();
    } catch (e) {
      if (_current) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : e is FormatException
                  ? e.message
                  : _uploading
                      ? l.adminUploadFailed
                      : l.adminErrorReadBytes;
          _done = _uploading;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _uploading = false;
        });
      }
    }
  }

  void _close() {
    if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
        canPop: !_uploading,
        child: AlertDialog(
            scrollable: true,
            title: Text(_uploading
                ? l.adminProcessingUpload
                : _done
                    ? (_count == null
                        ? l.adminUploadFailed
                        : _errors.isEmpty
                            ? l.adminUploadComplete
                            : l.adminImportWithErrors)
                    : l.adminBatchUploadTitle),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_uploading) ...[
                    Text('${l.adminParsing} $_filename…'),
                    const LinearProgressIndicator()
                  ] else if (!_done) ...[
                    Text(l.adminBatchUploadSubtitle),
                    const SizedBox(height: 12),
                    Text(l.adminPreparationLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l.adminPreparationSubtitle),
                    TextButton.icon(
                        onPressed: _busy ? null : _download,
                        icon: const Icon(Icons.download),
                        label: Text(l.adminDownloadTemplate))
                  ],
                  if (_count != null) Text(l.adminUploadSuccess(_count!)),
                  if (_error.isNotEmpty) Text(_error),
                  if (_errors.isNotEmpty) SelectableText(_errors.join('\n')),
                ]),
            actions: _uploading
                ? []
                : [
                    TextButton(
                        onPressed: _close,
                        child: Text(_done ? l.done : l.cancel)),
                    if (!_done)
                      ElevatedButton(
                          onPressed: _busy ? null : _choose,
                          child: Text(l.adminChooseFile)),
                  ]));
  }
}
