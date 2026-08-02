import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/cozy_dialog_sheet.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';

class GamePortalButton extends StatelessWidget {
  final VoidCallback onTap;

  const GamePortalButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.quizStart,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: CozyTheme.of(context).primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: CozyTheme.of(context).primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CozyTheme.of(context).primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: Icon(
                  Icons.school_rounded,
                  color: CozyTheme.of(context).textInverse,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizFloatingWindow extends StatelessWidget {
  final VoidCallback onClose;
  final Widget child;

  const QuizFloatingWindow({
    super.key,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CozyDialogSheet(onTapOutside: onClose, child: child);
  }
}
