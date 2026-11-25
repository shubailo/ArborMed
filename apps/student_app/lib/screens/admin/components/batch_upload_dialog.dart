import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api_exceptions.dart';
import '../../../services/admin_question_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class BatchUploadDialog {
  static Future<void> show(
    BuildContext context, {
    required AdminQuestionProvider questionProvider,
    required VoidCallback onComplete,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Initial Prompt Dialog
    final pickNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminBatchUploadTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminBatchUploadSubtitle),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminPreparationLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.adminPreparationSubtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              questionProvider.downloadQuestionsTemplate(),
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(l10n.adminDownloadTemplate),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminChooseFile),
          ),
        ],
      ),
    );

    if (pickNow != true || !context.mounted) return;

    // 2. Pick File
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );

    if (result == null || !context.mounted) return;

    // 3. Process Upload
    final fileName = result.files.single.name;
    final bytes = result.files.single.bytes;

    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminErrorReadBytes),
          ),
        );
      }
      return;
    }

    final upload = questionProvider.uploadQuestionsBatch(bytes, fileName);
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: upload,
        builder: (ctx, snapshot) {
          final processing = snapshot.connectionState != ConnectionState.done;
          final data = snapshot.data;
          // Older backends returned the processed count only in the message.
          final count = data?['imported'] as int? ??
              int.tryParse(RegExp(r'^Successfully processed (\d+) questions$')
                      .firstMatch(data?['message']?.toString() ?? '')
                      ?.group(1) ??
                  '');
          final error = snapshot.error;
          final errors = error is ApiException
              ? error.message
              : (data?['errors'] as List?)?.take(3).join('\n') ?? '';
          return PopScope(
            canPop: !processing,
            child: AlertDialog(
              title: Text(processing
                  ? l10n.adminProcessingUpload
                  : count == null
                      ? l10n.adminUploadFailed
                      : l10n.adminUploadComplete),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (processing) ...[
                      Text('${l10n.adminParsing} $fileName…'),
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ] else ...[
                      if (count != null) Text(l10n.adminUploadSuccess(count)),
                      if (errors.isNotEmpty) Text(errors),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!processing)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(ctx, count != null && count > 0),
                    child: Text(l10n.done),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (changed == true && context.mounted) onComplete();
  }
}
