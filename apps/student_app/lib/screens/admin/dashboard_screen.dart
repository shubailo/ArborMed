import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/admin_user_provider.dart';
import '../../../services/admin_question_provider.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import '../../theme/cozy_theme.dart';
import 'components/admin_csv_helper.dart';
import 'components/admin_notification_dialog.dart';
import 'components/batch_upload_dialog.dart';
import 'components/question_editor_dialog.dart';
import 'components/kpi_card_row.dart';
import 'components/proficiency_chart.dart';
import '../../generated/l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  int? _currentSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TopicProvider>().fetchTopics();
      _refresh();
    });
  }

  void _refresh() {
    final userProvider = context.read<AdminUserProvider>();
    userProvider.fetchQuestionStats(topicId: _currentSubjectId);
    userProvider.fetchAdminSummary(topicId: _currentSubjectId);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final subjects = context.watch<TopicProvider>().topics;
    final tabs = <({int? id, String label})>[
      (id: null, label: l10n.quizSubjects),
      for (final topic in subjects)
        if (topic['parent_id'] == null && topic['id'] is int)
          (
            id: topic['id'] as int,
            label: (topic['name_$locale'] ?? topic['name_en'] ?? topic['slug']).toString(),
          ),
    ];
    return Consumer<AdminUserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: CozyTheme.of(context).background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return RepaintBoundary(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userProvider.dashboardLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      _buildHeader(tabs),
                      const SizedBox(height: 24),
                      if (userProvider.dashboardLoading)
                        _buildQuickActions(userProvider)
                      else if (userProvider.dashboardFailed) ...[
                        Text(l10n.error),
                        TextButton(onPressed: _refresh, child: Text(l10n.retry)),
                        _buildQuickActions(userProvider),
                      ] else if (isMobile) ...[
                        KpiCardRow(userProvider: userProvider, isMobile: isMobile),
                        const SizedBox(height: 16),
                        _buildQuickActions(userProvider),
                        const SizedBox(height: 24),
                      ] else
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: KpiCardRow(userProvider: userProvider, isMobile: isMobile),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildQuickActions(userProvider),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: isMobile ? 16 : 32),
                      if (!userProvider.dashboardLoading && !userProvider.dashboardFailed)
                        RepaintBoundary(
                          child: ProficiencyChart(data: userProvider.adminSummary),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(List<({int? id, String label})> tabs) {
    final activeTab = tabs.firstWhere(
      (tab) => tab.id == _currentSubjectId,
      orElse: () => tabs.first,
    );

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
            PopupMenuButton<int>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (index) {
                setState(() {
                  _currentSubjectId = tabs[index].id;
                });
                _refresh();
              },
              itemBuilder: (context) => tabs.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value.label,
                    style: GoogleFonts.quicksand(
                      color: CozyTheme.of(context, listen: false).textPrimary,
                    ),
                  ),
                );
              }).toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeTab.label,
                    style: GoogleFonts.quicksand(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CozyTheme.of(context, listen: false).textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more,
                    size: 28,
                    color: CozyTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(),
      ],
    );
  }

  Widget _buildQuickActions(AdminUserProvider userProvider) {
    final palette = CozyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -10,
            child: Icon(
              Icons.bolt_rounded,
              size: 80,
              color: palette.accent.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildActionGrid(userProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(AdminUserProvider userProvider) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(l10n.add, Icons.add_circle_outline, () {
                showDialog(
                  context: context,
                  builder: (context) => QuestionEditorDialog(
                    question: null,
                    topics: Provider.of<TopicProvider>(
                      context,
                      listen: false,
                    ).topics,
                    onSaved: () {
                      _refresh();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionBtn(
                l10n.adminImport,
                Icons.description_outlined,
                () => BatchUploadDialog.show(
                  context,
                  questionProvider: context.read<AdminQuestionProvider>(),
                  onComplete: _refresh,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                l10n.adminReport,
                Icons.file_download_outlined,
                userProvider.dashboardLoading || userProvider.dashboardFailed || userProvider.questionStats.isEmpty
                    ? null
                    : () async {
                        try {
                          await AdminCsvHelper.downloadUserStats(userProvider.questionStats);
                        } catch (_) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminExportFailed)));
                        }
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionBtn(
                l10n.adminNotification,
                Icons.email_outlined,
                () {
                  showDialog(
                    context: context,
                    builder: (c) => const AdminNotificationDialog(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback? onTap) {
    final palette = CozyTheme.of(context, listen: false);

    return Tooltip(message: onTap == null ? l10n.adminExportUnavailable : label, child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: palette.textSecondary.withValues(alpha: 0.05),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onTap == null ? Theme.of(context).disabledColor : palette.textPrimary, size: 18),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onTap == null ? Theme.of(context).disabledColor : palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
