import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/stats_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../../../widgets/analytics/weakness_radar_chart.dart'; 

class UserHistoryDialog extends StatefulWidget {
  final UserPerformance user;
  final bool isStudentMode;

  const UserHistoryDialog({super.key, required this.user, this.isStudentMode = true});

  @override
  State<UserHistoryDialog> createState() => _UserHistoryDialogState();
}

class _UserHistoryDialogState extends State<UserHistoryDialog> {
  Map<String, dynamic>? _analytics;
  bool _loadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      stats.fetchUserHistory(widget.user.id);
      _loadAnalytics(stats);
    });
  }

  Future<void> _loadAnalytics(StatsProvider stats) async {
    final data = await stats.fetchAdminUserAnalytics(widget.user.id);
    if (mounted) {
      setState(() {
        _analytics = data;
        _loadingAnalytics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatsProvider>(context);
    final history = provider.userHistory;

    final palette = CozyTheme.of(context);

    return Dialog(
      backgroundColor: palette.background,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study History',
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isStudentMode 
                        ? "Medical ID: #${widget.user.id.toString().padLeft(3, '0')}"
                        : widget.user.email,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ANALYTICS SECTION
            if (widget.isStudentMode) ...[
               Text(
                'Predictive Analytics',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                 height: 220,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: palette.surface,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: palette.primary.withValues(alpha: 0.1)),
                 ),
                 child: _loadingAnalytics 
                    ? const Center(child: CircularProgressIndicator())
                    : _analytics == null 
                        ? Center(child: Text("No analytics available", style: TextStyle(color: palette.textSecondary)))
                        : Row(
                            children: [
                              // Radar Chart
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: WeaknessRadarChart(
                                        data: (_analytics!['readiness']['breakdown'] as List)
                                            .map((e) => ReadinessDetail.fromJson(e))
                                            .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Readiness: ${_analytics!['readiness']['overallReadiness']}%", 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: palette.primary)
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Recommendations Summary
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text("Needs Attention:", style: TextStyle(fontWeight: FontWeight.bold, color: palette.textSecondary, fontSize: 12)),
                                     const SizedBox(height: 8),
                                     Expanded(
                                       child: ListView(
                                         children: (_analytics!['smartReview'] as List).take(3).map((item) {
                                            final review = SmartReviewItem.fromJson(item);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, size: 16, color: palette.warning),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      review.topic,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${review.retention.toInt()}%",
                                                    style: TextStyle(fontSize: 12, color: palette.error),
                                                  ),
                                                ],
                                              ),
                                            );
                                         }).toList(),
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 24),
            ],
            

            const SizedBox(height: 24),
            

            
            Text(
              'Detail Activity Log',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                      ? Center(
                          child: Text(
                            'No activity recorded yet',
                            style: GoogleFonts.quicksand(
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            return _buildHistoryCard(entry);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(UserHistoryEntry entry) {
    final palette = CozyTheme.of(context);
    final Color statusColor = entry.isCorrect ? palette.success : palette.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Subject & Section
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.subjectName,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CozyTheme.of(context).primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.sectionName,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.isCorrect ? 'CORRECT' : 'WRONG',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Question Text
          Text(
            entry.questionText,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: CozyTheme.of(context).textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Footer Row
          Row(
            children: [
              // Bloom Level
              _buildMetric(
                Icons.school,
                'Bloom ${entry.bloomLevel}',
                CozyTheme.of(context).accent,
              ),
              const SizedBox(width: 16),
              
              // Response Time
              _buildMetric(
                Icons.timer,
                '${(entry.responseTimeMs / 1000).toStringAsFixed(1)}s',
                CozyTheme.of(context).textSecondary,
              ),
              const Spacer(),
              
              // Timestamp
              Text(
                timeago.format(entry.createdAt),
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: CozyTheme.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }


}
