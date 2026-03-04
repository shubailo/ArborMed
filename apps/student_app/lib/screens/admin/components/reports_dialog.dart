import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../services/stats_provider.dart';
import '../../../../models/report.dart';

class ReportsDialog extends StatefulWidget {
  final int questionId;

  const ReportsDialog({super.key, required this.questionId});

  @override
  State<ReportsDialog> createState() => _ReportsDialogState();
}

class _ReportsDialogState extends State<ReportsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(
        context,
        listen: false,
      ).fetchReports(widget.questionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: palette.surface,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question Reports',
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.textSecondary),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Consumer<StatsProvider>(
              builder: (context, stats, child) {
                if (stats.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (stats.questionReports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "No reports found for this question.",
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: stats.questionReports.length,
                    separatorBuilder: (ctx, i) => Divider(
                      color: palette.textSecondary.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final report = stats.questionReports[index];
                      return _buildReportItem(report, palette);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Report report, CozyPalette palette) {
    final isPending = report.status == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(report.status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.reasonCategory.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                report.createdAt.toLocal().toString().split('.')[0],
                style: TextStyle(fontSize: 11, color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (report.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.description,
                style: TextStyle(color: palette.textPrimary, fontSize: 13),
              ),
            ),
          if (report.adminNotes != null && report.adminNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Admin Note: ${report.adminNotes}",
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateStatus(report.id, 'ignored'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text("Ignore"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateStatus(report.id, 'resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text("Resolve"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'ignored':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _updateStatus(int reportId, String status) async {
    final success = await Provider.of<StatsProvider>(
      context,
      listen: false,
    ).updateReportStatus(reportId, status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Report updated" : "Failed to update report"),
        ),
      );
    }
  }
}
