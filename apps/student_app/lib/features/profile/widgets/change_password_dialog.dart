import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void showChangePasswordDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final owner = auth.user?.id;
  if (owner == null) return;
  var currentPassword = '';
  var newPassword = '';
  var confirmation = '';
  bool isSubmitting = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => PopScope(
        canPop: !isSubmitting,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: CozyTheme.of(context).paperCream,
          title: Text(AppLocalizations.of(context)!.changePassword,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: CozyTheme.of(context).textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => currentPassword = value,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.currentPassword,
                  hintText: "Enter your current password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      color: CozyTheme.of(context).textSecondary,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureCurrent = !obscureCurrent;
                      });
                    },
                    tooltip: obscureCurrent ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
              TextField(
                onChanged: (value) => newPassword = value,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newPassword,
                  hintText: "Enter your new password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: CozyTheme.of(context).textSecondary,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureNew = !obscureNew;
                      });
                    },
                    tooltip: obscureNew ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
              TextField(
                onChanged: (value) => confirmation = value,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPassword,
                  hintText: "Repeat your new password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: CozyTheme.of(context).textSecondary,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                    tooltip: obscureConfirm ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase(),
                  style: TextStyle(
                      color: CozyTheme.of(context).textSecondary,
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (auth.user?.id != owner) {
                        Navigator.pop(context);
                        return;
                      }
                      if (newPassword != confirmation) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .passwordsDoNotMatch)));
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await auth.changePassword(currentPassword, newPassword);
                      } catch (e) {
                        if (!context.mounted ||
                            ModalRoute.of(context)?.isCurrent != true) {
                          return;
                        }
                        if (!auth.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text(AppLocalizations.of(context)!.error)));
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (_) => false);
                          return;
                        }
                        if (auth.user?.id != owner) {
                          Navigator.pop(context);
                          return;
                        }
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "${AppLocalizations.of(context)!.error}: ${e.toString()}")));
                        return;
                      }
                      if (!context.mounted ||
                          ModalRoute.of(context)?.isCurrent != true) {
                        return;
                      }
                      if (auth.isAuthenticated) {
                        Navigator.pop(context);
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.passwordChanged)));
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context)!.update,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CozyTheme.of(context).textInverse)),
            ),
          ],
        ),
      ),
    ),
  );
}
