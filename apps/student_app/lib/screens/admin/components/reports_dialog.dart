import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/stats_provider.dart';
import '../../../theme/cozy_theme.dart';

class ReportsDialog extends StatefulWidget {
  final int questionId;
  final String questionText;

  const ReportsDialog({
    super.key,
    required this.questionId,
    required this.questionText,
  });

  @override
  State<ReportsDialog> createState() => _ReportsDialogState();
}

class _ReportsDialogState extends State<ReportsDialog> {
  bool _isLoading = true;
  List<QuestionReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final reports = await stats.fetchQuestionReports(widget.questionId);
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(QuestionReport report, String newStatus) async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final success = await stats.updateReportStatus(report.id, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated')),
      );
      _fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return Dialog(
      backgroundColor: palette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported Issues',
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Question #${widget.questionId}',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1)),
              ),
              child: Text(
                widget.questionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: palette.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                      ? Center(
                          child: Text(
                            'No reports found.',
                            style: GoogleFonts.quicksand(
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _reports.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return _buildReportCard(report, palette);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(QuestionReport report, CozyPalette palette) {
    Color statusColor;
    switch (report.status) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'ignored':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.reasonCategory,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(report.createdAt),
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (report.description != null && report.description!.isNotEmpty) ...[
            Text(
              report.description!,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (report.reporterEmail != null)
             Text(
              'Reported by: ${report.reporterEmail}',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (report.status != 'resolved')
                TextButton.icon(
                  onPressed: () => _updateStatus(report, 'resolved'),
                  icon: const Icon(Icons.check, size: 16, color: Colors.green),
                  label: const Text('Resolve', style: TextStyle(color: Colors.green)),
                ),
              if (report.status != 'ignored')
                TextButton.icon(
                  onPressed: () => _updateStatus(report, 'ignored'),
                  icon: const Icon(Icons.block, size: 16, color: Colors.grey),
                  label: const Text('Ignore', style: TextStyle(color: Colors.grey)),
                ),
              if (report.status != 'pending')
                 TextButton.icon(
                  onPressed: () => _updateStatus(report, 'pending'),
                  icon: const Icon(Icons.undo, size: 16, color: Colors.orange),
                  label: const Text('Mark Pending', style: TextStyle(color: Colors.orange)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
