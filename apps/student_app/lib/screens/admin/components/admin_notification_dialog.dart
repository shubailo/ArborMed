import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../services/admin_user_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class AdminNotificationDialog extends StatefulWidget {
  const AdminNotificationDialog({super.key});

  @override
  State<AdminNotificationDialog> createState() =>
      _AdminNotificationDialogState();
}

class _AdminNotificationDialogState extends State<AdminNotificationDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _failed = false;
  (String, String)? _previousDraft;
  String? _requestId;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_isSending,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.adminNotificationBroadcastTitle,
                  style: GoogleFonts.quicksand(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.adminNotificationBroadcastDesc,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  enabled: !_isSending,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .adminNotificationLabelTitle,
                    hintText: AppLocalizations.of(context)!
                        .adminNotificationHintTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  enabled: !_isSending,
                  maxLength: 4000,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .adminNotificationLabelMessage,
                    hintText: AppLocalizations.of(context)!
                        .adminNotificationHintMessage,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_failed)
                  Text(AppLocalizations.of(context)!.adminBroadcastFailed,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSending ? null : () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CozyTheme.of(context).primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(AppLocalizations.of(context)!.adminSendNow),
                    ),
                  ],
                ),
              ],
            )),
          ),
        ));
  }

  Future<void> _send() async {
    if (_isSending) return;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.adminErrorFillAllFields)));
      return;
    }

    final draft = (title, message);
    if (_previousDraft != draft) {
      _requestId = const Uuid().v4();
      _previousDraft = draft;
    }
    setState(() {
      _failed = false;
      _isSending = true;
    });
    try {
      final count = await context
          .read<AdminUserProvider>()
          .sendBroadcast(title, message, _requestId!);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final label =
          AppLocalizations.of(context)!.adminBroadcastDelivered(count);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(label)));
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _failed = true;
        });
      }
    }
  }
}
