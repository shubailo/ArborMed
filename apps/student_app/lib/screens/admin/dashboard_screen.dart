import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import 'components/admin_csv_helper.dart';
import 'components/admin_notification_dialog.dart';
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
  String _selectedType = '';
  List<Map<String, dynamic>> _tabs = [];
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final provider = Provider.of<StatsProvider>(context, listen: false);

    // Fetch aggregated stats for the specific subject
    provider.fetchQuestionStats(topicId: _currentSubjectId);
    provider.fetchWallOfPain();

    if (_tabs.isEmpty) {
      provider.fetchTopics().then((_) {
        if (mounted) _buildDynamicTabs();
      });
    }

    final activeSlug = _getActiveSubjectSlug();
    if (activeSlug != null) {
      provider.fetchSubjectDetail(activeSlug);
    } else {
      // Global View: Fetch summary of all subjects
      provider.fetchAdminSummary();
    }
  }

  void _buildDynamicTabs() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final subjects = [
      l10n.quizSubjectPathophysiology,
      l10n.quizSubjectPathology,
      l10n.quizSubjectMicrobiology,
      l10n.quizSubjectPharmacology,
    ];

    setState(() {
      _tabs = [
        {'label': l10n.quizSubjects, 'type': '', 'topicId': null, 'slug': null},
        ...subjects.map((name) {
          final t = stats.topics.firstWhere(
            (topic) =>
                (topic['name_en']?.toString() == name) ||
                (topic['name_hu']?.toString() == name) ||
                (topic['name']?.toString() == name),
            orElse: () => {'id': null, 'slug': null},
          );
          return {
            'label': name,
            'type': '',
            'topicId': t['id'],
            'slug': t['slug'],
          };
        }),
        {'label': l10n.quizECG, 'type': 'ecg', 'topicId': null, 'slug': 'ecg'},
        {
          'label': l10n.quizResults, // or something for Case
          'type': 'case_study',
          'topicId': null,
          'slug': 'case-studies',
        },
      ];
      if (_isInit && _tabs.isNotEmpty) {
        // Default to "All" (index 0)
        _currentSubjectId = _tabs[0]['topicId'];
        _selectedType = _tabs[0]['type'] ?? '';
        _isInit = false;
        // removed _refresh() here to avoid duplicate call
      }
    });
  }

  String? _getActiveSubjectSlug() {
    if (_tabs.isEmpty) return null;
    final tab = _tabs.firstWhere(
      (t) => t['topicId'] == _currentSubjectId && t['type'] == _selectedType,
      orElse: () => _tabs[0],
    );
    return tab['slug'];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, child) {
        // Only show full screen loader if we have NO data at all
        if (_tabs.isEmpty ||
            (stats.isLoading &&
                stats.questionStats.isEmpty &&
                stats.adminSummary.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

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
                      if (stats.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      _buildHeader(stats),
                      const SizedBox(height: 24),
                      if (isMobile) ...[
                        KpiCardRow(stats: stats, isMobile: isMobile),
                        const SizedBox(height: 16),
                        _buildQuickActions(stats),
                        const SizedBox(height: 24),
                      ] else
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: KpiCardRow(
                                    stats: stats, isMobile: isMobile),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildQuickActions(stats),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: isMobile ? 16 : 32),
                      Builder(builder: (context) {
                        final activeSlug = _getActiveSubjectSlug();
                        final chartData = (activeSlug == null)
                            ? stats.adminSummary
                            : (stats.sectionMastery[activeSlug] ?? []);
                        return RepaintBoundary(
                            child: ProficiencyChart(data: chartData));
                      }),
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

  Widget _buildHeader(StatsProvider stats) {
    final activeTab = _tabs.firstWhere(
      (t) => t['topicId'] == _currentSubjectId && t['type'] == _selectedType,
      orElse: () => _tabs[0],
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
                  _selectedType = _tabs[index]['type']!;
                  _currentSubjectId = _tabs[index]['topicId'];
                });
                _refresh();
              },
              itemBuilder: (context) => _tabs.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value['label'],
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
                    activeTab['label'],
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
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.adminSemester,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: CozyTheme.of(context, listen: false).textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(),
      ],
    );
  }

  Widget _buildQuickActions(StatsProvider stats) {
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
            child: _buildActionGrid(stats),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(StatsProvider stats) {
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
                    topics: Provider.of<StatsProvider>(
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
                () {
                  AdminCsvHelper.downloadQuestions(stats.adminQuestions);
                },
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
                () {
                  AdminCsvHelper.downloadUserStats(stats.questionStats);
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

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    final palette = CozyTheme.of(context, listen: false);

    return InkWell(
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
                Icon(icon, color: palette.textPrimary, size: 18),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
