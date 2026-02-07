import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import 'responsive/admin_responsive_shell.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    // 🔇 Silence music when entering Admin Zone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).pauseTemporary();
    });
  }

  @override
  void dispose() {
    // 🔊 Resume music when leaving Admin Zone (if it was playing)
    // We use a lingering reference check or just assume if we are disposing, we are leaving.
    // Note: If the app is closing, it doesn't matter. If we are navigating away, we want music back.
    // We need to be careful not to trigger this if we are just rebuilding.
    // However, AdminShell is usually top-level.
    // Ideally, we'd use DidPop, but dispose is good enough for a Shell swap.
    // Need to use a microtask or verify context is valid if using Provider in dispose (sometimes risky).
    // Better safely invoking it.

    // Defer the resume slightly to ensure the next page loads? No, immediate is fine.
    // Since we need context, and context might be unmounted?
    // Actually, Provider lookup in dispose can be tricky.
    // Let's rely on standard Flutter lifecycle.
    super.dispose();
  }

  @override
  void deactivate() {
    // Resume when this view is removed from tree (Navigating away)
    Provider.of<AudioProvider>(context, listen: false).resumeTemporary();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return const AdminResponsiveShell();
  }
}
