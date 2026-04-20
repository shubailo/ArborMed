import 'package:flutter/material.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class InventoryOverview extends StatelessWidget {
  final StatsProvider stats;

  const InventoryOverview({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (stats.inventorySummary.isEmpty && !stats.isLoading) {
      return Center(
        child: Text(l10n.adminNoDataAvailable),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stats.inventorySummary.length,
      itemBuilder: (context, index) {
        final subject = stats.inventorySummary[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: palette.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Row(
              children: [
                Text(
                  subject['name_en']?.toString() ??
                      subject['name']?.toString() ??
                      'Unnamed Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    "${subject['total']} Q",
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              ...subject['sections'].map<Widget>((section) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.paperWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: palette.shadowSmall,
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      title: Text(
                        section['name_en']?.toString() ??
                            section['name']?.toString() ??
                            'Unnamed Section',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                      ),
                      trailing: Text(
                        "${section['total']} ${l10n.adminItems}",
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [1, 2, 3, 4].map((level) {
                              final count =
                                  section['bloomCounts'][level.toString()] ?? 0;
                              return _buildBloomStat(context, level, count);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBloomStat(BuildContext context, int level, int count) {
    Color color;
    String label;
    switch (level) {
      case 1:
        color = Colors.green;
        label = "R";
        break; // Remember
      case 2:
        color = Colors.blue;
        label = "U";
        break; // Understand
      case 3:
        color = Colors.orange;
        label = "Ap";
        break; // Apply
      case 4:
        color = Colors.red;
        label = "An";
        break; // Analyze
      default:
        color = Colors.grey;
        label = "L";
        break;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "L$level",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        Text(
          "$count",
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
      ],
    );
  }
}
