import 'package:flutter/material.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../services/api_service.dart';
import '../../../generated/l10n/app_localizations.dart';

class ECGCasesTable extends StatelessWidget {
  final StatsProvider stats;
  final Function(ECGCase) onEditCase;
  final Function(ECGCase) onDeleteCase;

  const ECGCasesTable({
    super.key,
    required this.stats,
    required this.onEditCase,
    required this.onDeleteCase,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (stats.isLoading && stats.ecgCases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stats.ecgCases.isEmpty) {
      return Center(
        child: Text(
          l10n.adminNoEcgCasesFound,
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: palette.textPrimary.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    l10n.adminTableId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.adminTableImage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.adminTableDiagnosis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    l10n.adminTableDifficulty,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    l10n.adminTableActions,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: stats.ecgCases.length,
            itemBuilder: (context, index) {
              final c = stats.ecgCases[index];
              return Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: palette.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Center(child: Text(c.id.toString())),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          c.imageUrl.startsWith('http')
                              ? c.imageUrl
                              : '${ApiService.baseUrl}${c.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.diagnosisCode ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            c.diagnosisName ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.difficulty == 'beginner'
                                ? palette.success.withValues(alpha: 0.1)
                                : (c.difficulty == 'advanced'
                                    ? palette.error.withValues(alpha: 0.1)
                                    : palette.primary.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: c.difficulty == 'beginner'
                                  ? palette.success
                                  : (c.difficulty == 'advanced'
                                      ? palette.error
                                      : palette.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: "Edit Case",
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 18,
                            ),
                            onPressed: () => onEditCase(c),
                          ),
                          IconButton(
                            tooltip: "Delete Case",
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => onDeleteCase(c),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
