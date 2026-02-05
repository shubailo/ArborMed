import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../theme/cozy_theme.dart';

enum ToastType { success, error, info }

class CozyToast {
  static void show(BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 📳 Haptic Feedack on appearance
    HapticFeedback.lightImpact();

    final Color borderColor = _getBorderColor(type);
    final IconData icon = _getIcon(type);
    final Color iconColor = _getIconColor(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        width: 400, // Max width for wider screens
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CozyTheme.paperCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: CozyTheme.textPrimary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              
              // Text
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.notoSans(
                    color: CozyTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getBorderColor(ToastType type) {
    switch (type) {
      case ToastType.success: return CozyTheme.success;
      case ToastType.error: return CozyTheme.error;
      case ToastType.info: return CozyTheme.primary;
    }
  }

  static Color _getIconColor(ToastType type) {
    switch (type) {
      case ToastType.success: return Colors.green[700]!;
      case ToastType.error: return Colors.red[700]!;
      case ToastType.info: return CozyTheme.primary;
    }
  }

  static IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success: return Icons.check_circle_outline_rounded;
      case ToastType.error: return Icons.error_outline_rounded;
      case ToastType.info: return Icons.info_outline_rounded;
    }
  }
}
