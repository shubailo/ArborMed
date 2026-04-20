import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/admin/icon_manager_dialog.dart';
import '../../generated/l10n/app_localizations.dart';
import 'components/quote_editor_dialog.dart';

class AdminQuotesScreen extends StatefulWidget {
  const AdminQuotesScreen({super.key});

  @override
  State<AdminQuotesScreen> createState() => _AdminQuotesScreenState();
}

class _AdminQuotesScreenState extends State<AdminQuotesScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchAdminQuotes();
    });
  }

  // Removed _pickAndUploadCustomImage as it is now handled by IconManagerDialog

  void _openIconManager(
      {bool isSelectionMode = false, Function(String)? onSelected}) {
    showDialog(
      context: context,
      builder: (context) => IconManagerDialog(
        isSelectionMode: isSelectionMode,
        onIconSelected: onSelected,
      ),
    );
  }

  // Removed _randomizeIcon as we now use random_gallery mode


  void _confirmDelete(Quote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.adminDeleteQuote),
        content: Text(AppLocalizations.of(context)!.adminDeleteQuote), // Using same for now
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<StatsProvider>(context, listen: false)
                      .deleteQuote(quote.id);
              if (success && context.mounted) {
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: Padding(
        padding: const EdgeInsets.all(32), // Standardized 32px padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<StatsProvider>(
              builder: (context, stats, _) => _buildHeader(stats),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<StatsProvider>(
                builder: (context, stats, _) {
                  if (stats.isLoading && stats.adminQuotes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (stats.adminQuotes.isEmpty) {
                    return Center(
                      child: Text(
                        "No quotes found. Add some to start the rotation!",
                        style: TextStyle(
                            color: CozyTheme.of(context)
                                .textSecondary
                                .withValues(alpha: 0.5)),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: stats.adminQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = stats.adminQuotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // More rounded
                          side: BorderSide(
                              color: CozyTheme.of(context)
                                  .textSecondary
                                  .withValues(alpha: 0.1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EN: "${quote.textEn}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: CozyTheme.of(context).textPrimary,
                                ),
                              ),
                              if (quote.textHu.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'HU: "${quote.textHu}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: CozyTheme.of(context).textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              "- ${quote.author}",
                              style: TextStyle(
                                  color: CozyTheme.of(context).textSecondary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: CozyTheme.of(context).textSecondary,
                                    size: 20),
                                onPressed: () {
                                  showDialog(context: context, barrierDismissible: false, builder: (context) => QuoteEditorDialog(quote: quote));
                                },
                                tooltip: "Edit quote",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: CozyTheme.of(context).error,
                                    size: 20),
                                onPressed: () => _confirmDelete(quote),
                                tooltip: "Delete quote",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StatsProvider stats) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.adminQuotes,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CozyTheme.of(context).textPrimary,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminQuotesSubtitle,
              style: TextStyle(
                fontSize: 16,
                color: CozyTheme.of(context).textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildStatusChip("${stats.adminQuotes.length} ${l10n.adminQuotes}"),
            OutlinedButton.icon(
              onPressed: () => _openIconManager(isSelectionMode: false),
              icon: const Icon(Icons.collections, size: 18),
              label: Text(l10n.adminManageIcons),
              style: OutlinedButton.styleFrom(
                foregroundColor: CozyTheme.of(context).textPrimary,
                side: BorderSide(
                    color: CozyTheme.of(context)
                        .textPrimary
                        .withValues(alpha: 0.2)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () { showDialog(context: context, barrierDismissible: false, builder: (context) => const QuoteEditorDialog()); },
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.adminAddQuote),
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CozyTheme.of(context).shadowSmall,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: CozyTheme.of(context).textSecondary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand',
        ),
      ),
    );
  }
}
