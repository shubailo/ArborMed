import 'package:flutter/material.dart';
import 'dart:ui';
import '../cozy/cozy_dialog_sheet.dart';

class GamePortalButton extends StatelessWidget {
  final VoidCallback onTap;

  const GamePortalButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const Center(
              child: Icon(Icons.school_rounded, color: Colors.white, size: 36),
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

  const QuizFloatingWindow({Key? key, required this.onClose, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CozyDialogSheet(
      onTapOutside: onClose,
      child: child,
    );
  }
}
