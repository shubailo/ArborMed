import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
                          onPressed: () => questionProvider.downloadQuestionsTemplate(),
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
            child: const Text("Cancel"),
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

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            bool isProcessing = true;
            String? errorMsg;
            int? successCount;

            // Start upload immediately
            Future.microtask(() async {
              final uploadResult = await questionProvider.uploadQuestionsBatch(
                bytes,
                fileName,
              );

              if (ctx.mounted) {
                setDialogState(() {
                  isProcessing = false;
                  if (uploadResult == null) {
                    errorMsg = "Server error or invalid file format.";
                  } else {
                    successCount = uploadResult['message'] != null
                        ? int.tryParse(uploadResult['message'].split(' ')[2])
                        : 0;
                    if (uploadResult['errors'] != null) {
                      errorMsg =
                          "Partial success with errors: \n${(uploadResult['errors'] as List).take(3).join('\n')}";
                    }
                  }
                });
              }
            });

            return AlertDialog(
              title: Text(
                isProcessing
                    ? l10n.adminProcessingUpload
                    : (errorMsg != null && successCount == null
                          ? l10n.adminUploadFailed
                          : l10n.adminUploadComplete),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing) ...[
                    Text("${l10n.adminParsing} $fileName..."),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ] else ...[
                    if (successCount != null) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.adminUploadSuccess(successCount!),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
              actions: [
                if (!isProcessing)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onComplete();
                    },
                    child: Text(l10n.done),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

