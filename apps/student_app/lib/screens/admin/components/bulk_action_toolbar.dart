import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class BulkActionToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const BulkActionToolbar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CozyTheme.of(context).primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: CozyTheme.of(context).primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.adminItemsSelected(selectedCount),
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: CozyTheme.of(context).primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClearSelection,
            child: Text(l10n.adminClearSelection),
          ),
          const VerticalDivider(width: 20, indent: 8, endIndent: 8),
          ElevatedButton.icon(
            onPressed: onMove,
            icon: const Icon(Icons.drive_file_move, size: 18),
            label: Text(l10n.adminMoveTo),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: Text(l10n.adminDeleteBatch),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

