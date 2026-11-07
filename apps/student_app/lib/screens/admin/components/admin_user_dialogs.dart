import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/models/performance.dart';
import '../../../theme/cozy_theme.dart';
import '../../../services/admin_user_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class AdminUserDialogs {
  static void showMessageDialog(
    BuildContext context,
    UserPerformance user,
    bool isStudentMode,
  ) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.adminPagerTitle(identifier)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.adminTypePagerMessage,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final success =
                  await Provider.of<AdminUserProvider>(context, listen: false)
                      .sendDirectMessage(user.id, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                final isHu = Localizations.localeOf(context).languageCode == 'hu';
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminMessageDispatched)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isHu
                              ? 'Nem sikerült elküldeni az üzenetet.'
                              : 'Failed to dispatch message.',
                        ),
                        backgroundColor: Colors.red,
                      ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary),
            child: Text(l10n.sent, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void confirmRoleChange(
    BuildContext context,
    UserPerformance user,
    String newRole,
    bool isStudentMode,
  ) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminChangeRole),
        content: Text(
            l10n.adminConfirmRoleChange(identifier, newRole)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<AdminUserProvider>(context, listen: false)
                      .updateUserRole(user.id, newRole);
              if (context.mounted) {
                Navigator.pop(context);
                final isHu = Localizations.localeOf(context).languageCode == 'hu';
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminUserRoleUpdated)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isHu
                              ? 'Nem sikerült módosítani a jogosultságot.'
                              : 'Failed to update user role.',
                        ),
                        backgroundColor: Colors.red,
                      ));
                }
              }
            },
            child: Text(l10n.success.toUpperCase()),
          ),
        ],
      ),
    );
  }

  static void confirmDeletion(
    BuildContext context,
    UserPerformance user,
    bool isStudentMode,
  ) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteUserTitle),
        content: Text(
            l10n.adminDeleteUserConfirm(identifier)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await Provider.of<AdminUserProvider>(context, listen: false)
                      .deleteUser(user.id);
              if (context.mounted) {
                Navigator.pop(context);
                final isHu = Localizations.localeOf(context).languageCode == 'hu';
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.adminDoctorRemoved)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        isHu
                            ? 'Nem sikerült törölni a felhasználót.'
                            : 'Failed to delete user.',
                      ),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete.toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
