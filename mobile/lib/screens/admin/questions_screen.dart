import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/stats_provider.dart';
import '../../services/api_service.dart';
import '../../../theme/cozy_theme.dart';
import 'ecg_editor_dialog.dart';
import 'components/question_editor_dialog.dart';
import '../../generated/l10n/app_localizations.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => AdminQuestionsScreenState();
}

class AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();

  // Selection State
  String _selectedType = ''; // '' means any
  int? _selectedTopicId;
  int? _selectedBloom;
  int? _currentSubjectId; // Track which subject tab is active

  // Sorting State
  String _sortBy = 'created_at';
  bool _isAscending = false;
  AdminQuestion? _selectedPreviewQuestion; // State for Split View
  DateTime? _debounceTimer;

  // Persistent filter state for each subject tab
  final Map<int?, int?> _subjectLastTopic = {};

  // Multi-Selection State
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  List<Map<String, dynamic>> _tabs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final provider = Provider.of<StatsProvider>(context, listen: false);

    // Determine which topic ID to use:
    // - If a section is selected (_selectedTopicId), use that
    // - Otherwise, if a subject tab is active (_currentSubjectId), use that
    // - Otherwise, null (show all)
    final effectiveTopicId = _selectedTopicId ?? _currentSubjectId;

    // 1. Fetch Questions
    // 1. Fetch Data
    if (_selectedType == 'ecg') {
      provider.fetchECGCases();
      // Also fetch diagnoses for the dropdowns
      provider.fetchECGDiagnoses();
    } else {
      provider.fetchAdminQuestions(
        page: _currentPage,
        search: _searchController.text,
        type: _selectedType,
        topicId: effectiveTopicId,
        bloomLevel: _selectedBloom,
        sortBy: _sortBy,
        order: _isAscending ? 'ASC' : 'DESC',
      );
    }

    // Fetch inventory summary ONLY if on "All" tab (no subject selected) and no specific filtering
    if (_currentSubjectId == null &&
        _selectedType.isEmpty &&
        _selectedBloom == null &&
        _searchController.text.isEmpty &&
        _selectedTopicId == null) {
      provider.fetchInventorySummary();
    }

    // 2. Fetch Topics if tabs are empty
    if (_tabs.isEmpty) {
      provider.fetchTopics().then((_) {
        if (mounted) _buildDynamicTabs();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer = DateTime.now();
    final currentTimer = _debounceTimer;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && currentTimer == _debounceTimer) {
        setState(() {
          _currentPage = 1;
        });
        _refresh();
      }
    });
  }

  void _buildDynamicTabs() {
    final l10n = AppLocalizations.of(context)!;
    final subjects = [
      l10n.quizSubjectPathophysiology,
      l10n.quizSubjectPathology,
      l10n.quizSubjectMicrobiology,
      l10n.quizSubjectPharmacology
    ];

    final stats = Provider.of<StatsProvider>(context, listen: false);
    setState(() {
      _tabs = [
        {'label': l10n.quizSubjects, 'type': '', 'topicId': null},
        ...subjects.map((name) {
          final t = stats.topics.firstWhere(
              (topic) =>
                  (topic['name_en']?.toString() == name) ||
                  (topic['name_hu']?.toString() == name) ||
                  (topic['name']?.toString() == name),
              orElse: () => {'id': null});
          return {
            'label': name,
            'type': '', // Empty type - filter by topicId only
            'topicId': t['id'],
          };
        }),
        {'label': l10n.quizECG, 'type': 'ecg', 'topicId': null},
        {'label': l10n.quizResults, 'type': 'case_study', 'topicId': null},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32), // Matched Dashboard padding
        child: Consumer<StatsProvider>(
          builder: (context, stats, child) {
            final palette = CozyTheme.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Header
                _buildHeader(stats),
                if (_isSelectionMode) _buildBulkActionToolbar(stats),
                const SizedBox(height: 24),

                // 2. Toolbar (Search, Filters, Batch, New)
                _buildToolbar(stats),
                const SizedBox(height: 24),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, anim, child) =>
                              Transform.translate(
                            offset: Offset(0, 30 * (1.0 - anim)),
                            child: Opacity(opacity: anim, child: child),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.textPrimary
                                      .withValues(alpha: 0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                                ...palette.shadowSmall,
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Content with Animation
                                      Positioned.fill(
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: (_currentSubjectId == null &&
                                                  _selectedType.isEmpty &&
                                                  _selectedBloom == null &&
                                                  _searchController
                                                      .text.isEmpty &&
                                                  _selectedTopicId == null)
                                              ? KeyedSubtree(
                                                  key: const ValueKey(
                                                      'overview'),
                                                  child:
                                                      _buildInventoryOverview(
                                                          stats),
                                                )
                                              : KeyedSubtree(
                                                  key: ValueKey(
                                                      'table_${_currentSubjectId ?? "all"}_${_selectedTopicId ?? "all"}'),
                                                  child: _selectedType == 'ecg'
                                                      ? _buildECGTable(stats)
                                                      : (stats.adminQuestions
                                                              .isNotEmpty
                                                          ? _buildTable(stats)
                                                          : Center(
                                                              child: Text(
                                                                  "No questions found.",
                                                                  style: GoogleFonts
                                                                      .outfit(
                                                                          color:
                                                                              palette.textSecondary)))),
                                                ),
                                        ),
                                      ),

                                      // Loading indicator overlay (Non-blocking)
                                      if (stats.isLoading) ...[
                                        (stats.adminQuestions.isEmpty &&
                                                stats.inventorySummary.isEmpty)
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : Positioned(
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                child: LinearProgressIndicator(
                                                  minHeight: 3,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          palette.primary),
                                                ),
                                              ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Pagination Footer
                                if (_selectedType != 'ecg' &&
                                    !(_currentSubjectId == null &&
                                        _selectedType.isEmpty &&
                                        _selectedBloom == null &&
                                        _searchController.text.isEmpty &&
                                        _selectedTopicId == null))
                                  _buildPaginationFooter(stats),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // PREVIEW PANEL (Split View)
                      if (_selectedPreviewQuestion != null) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildPreviewPanel(_selectedPreviewQuestion!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(StatsProvider stats) {
    final activeTab = _tabs.firstWhere(
      (t) => t['topicId'] == _currentSubjectId && t['type'] == _selectedType,
      orElse: () => _tabs[0],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupMenuButton<int>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (index) {
                setState(() {
                  // 1. Save current selection for previous subject before switching
                  _subjectLastTopic[_currentSubjectId] = _selectedTopicId;

                  _selectedType = _tabs[index]['type']!;
                  _currentSubjectId = _tabs[index]['topicId'];

                  // 2. Restore last selection for the new subject
                  _selectedTopicId = _subjectLastTopic[_currentSubjectId];

                  _currentPage = 1;
                });
                _refresh();
              },
              itemBuilder: (context) => _tabs.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value['label'],
                      style: GoogleFonts.quicksand(
                          color: CozyTheme.of(context, listen: false)
                              .textPrimary)),
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
                  Icon(Icons.expand_more,
                      size: 28,
                      color:
                          CozyTheme.of(context, listen: false).textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminQuestionBankTitle,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: CozyTheme.of(context, listen: false).textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Stats Chip
        _buildStatusChip("${stats.adminTotalQuestions} ${l10n.adminQuestionsSmall}"),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    final palette = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: palette.textInverse,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToolbar(StatsProvider stats) {
    final palette = CozyTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8), // Room for scrollbar if any
        child: Row(
          children: [
            // 1. Search Bar
            Container(
              width: 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.adminSearchQuestions,
                  hintStyle: GoogleFonts.quicksand(
                      color: palette.textSecondary.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: palette.primary),
                  fillColor: palette.paperWhite,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Type Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              width: 150,
              decoration: BoxDecoration(
                color: palette.paperWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: palette.textSecondary.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  hint: Text(l10n.adminAllTypes),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l10n.adminAllTypes)),
                    DropdownMenuItem(
                        value: 'single_choice', child: Text(l10n.quizTypeSingleChoice)),
                    DropdownMenuItem(
                        value: 'multiple_choice', child: Text(l10n.quizTypeMultipleChoice)),
                    DropdownMenuItem(
                        value: 'true_false', child: Text(l10n.quizTypeTrueFalse)),
                    DropdownMenuItem(value: 'matching', child: Text(l10n.quizTypeMatching)),
                    DropdownMenuItem(
                        value: 'relation_analysis', child: Text(l10n.quizTypeRelational)),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val ?? '';
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 3. Bloom Filter
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                width: 130,
                decoration: BoxDecoration(
                  color: palette.paperWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: palette.textSecondary.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedBloom,
                    isExpanded: true,
                    hint:
                        Text(l10n.adminLevel, style: GoogleFonts.quicksand(fontSize: 13)),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(l10n.adminAllLevels)),
                      ...[1, 2, 3, 4].map((l) =>
                          DropdownMenuItem(value: l, child: Text("${l10n.adminLevel} $l"))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBloom = val);
                      _refresh();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

            // 4. Topic Filter
            if (_currentSubjectId != null)
              Consumer<StatsProvider>(
                builder: (context, stats, _) {
                  final subjectSections = stats.topics.where((topic) {
                    return topic['parent_id'] == _currentSubjectId;
                  }).toList();

                  if (_selectedTopicId != null &&
                      !subjectSections.any((t) => t['id'] == _selectedTopicId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedTopicId != null) {
                        setState(() {
                          _selectedTopicId = null;
                          _subjectLastTopic[_currentSubjectId] = null;
                        });
                      }
                    });
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(maxWidth: 240),
                    decoration: BoxDecoration(
                      color: palette.paperWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: palette.textSecondary.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedTopicId,
                        isExpanded: true,
                        hint: Text(l10n.adminAllSections,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(fontSize: 13)),
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text(l10n.adminAllSections)),
                          ...subjectSections.map((topic) => DropdownMenuItem(
                                value: topic['id'] as int,
                              child: Text(
                                  (AppLocalizations.of(context)!.localeName == 'hu' 
                                      ? topic['name_hu'] 
                                      : topic['name_en'])?.toString() ??
                                      topic['name']?.toString() ??
                                      l10n.adminUnnamedSection,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.quicksand(fontSize: 13)),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTopicId = val;
                            _currentPage = 1;
                          });
                          _refresh();
                        },
                      ),
                    ),
                  );
                },
              ),
            if (_currentSubjectId != null) const SizedBox(width: 8),
            if (_currentSubjectId != null)
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                tooltip: l10n.adminManageSectionsTooltip,
                onPressed: () => _showManageSectionsDialog(),
                style: IconButton.styleFrom(
                  backgroundColor: palette.paperWhite,
                  foregroundColor: palette.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                      color: palette.textSecondary.withValues(alpha: 0.1)),
                ),
              ),
            const SizedBox(width: 16),

            // 5. Actions
            IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: l10n.adminBatchUploadTooltip,
              onPressed: _showBatchUploadDialog,
              style: IconButton.styleFrom(
                backgroundColor: palette.paperWhite,
                foregroundColor: palette.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _selectedType == 'ecg'
                  ? showECGEditor(null)
                  : showQuestionEditor(null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(_selectedType == 'ecg' ? l10n.adminNewECG : l10n.adminNewQuestion,
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.textInverse,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(StatsProvider stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column proportions
        const int textFlex = 3;
        const int typeFlex = 1;
        const int sectionFlex = 2;
        const int bloomFlex = 1;
        const int attemptsFlex = 1;
        const int accuracyFlex = 1;

        return Column(
          children: [
            // 1. STICKY HEADER
            Container(
              height: 56,
              decoration: BoxDecoration(
                color:
                    CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: stats.adminQuestions.isNotEmpty &&
                          _selectedIds.length == stats.adminQuestions.length,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds
                                .addAll(stats.adminQuestions.map((q) => q.id));
                          } else {
                            _selectedIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(
                      width: 50,
                      child: Center(
                          child: Text(AppLocalizations.of(context)!.adminTableId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)))),
                  _buildFlexHeaderCell(l10n.adminTableQuestionText, textFlex),
                  _buildFlexHeaderCell(l10n.adminTableType, typeFlex, sortKey: 'type', center: true),
                  _buildFlexHeaderCell(l10n.adminTableSection, sectionFlex,
                      sortKey: 'topic_name', center: true),
                  _buildFlexHeaderCell(l10n.adminTableBloom, bloomFlex,
                      sortKey: 'bloom_level', center: true),
                  _buildFlexHeaderCell(l10n.adminTableAttempts, attemptsFlex,
                      sortKey: 'attempts', center: true),
                  _buildFlexHeaderCell(l10n.adminTableAccuracy, accuracyFlex,
                      sortKey: 'success_rate', center: true),
                  SizedBox(
                      width: 80,
                      child: Center(
                          child: Text(l10n.adminTableActions,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)))),
                ],
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: ListView.builder(
                  itemCount: stats.adminQuestions.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final q = stats.adminQuestions[index];
                    return _buildQuestionRowItem(q, stats, textFlex, typeFlex,
                        sectionFlex, bloomFlex, attemptsFlex, accuracyFlex);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8), // Reduced bottom padding
          ],
        );
      },
    );
  }

  Widget _buildQuestionRowItem(
      AdminQuestion q,
      StatsProvider stats,
      int textFlex,
      int typeFlex,
      int sectionFlex,
      int bloomFlex,
      int attemptsFlex,
      int accuracyFlex) {
    final accuracy = q.successRate;
    Color accuracyColor = Colors.grey;
    if (q.attempts > 0) {
      if (accuracy < 40) {
        accuracyColor = Colors.red;
      } else if (accuracy < 70) {
        accuracyColor = Colors.orange;
      } else {
        accuracyColor = Colors.green;
      }
    }

    return InkWell(
      onTap: () {
        setState(() => _selectedPreviewQuestion = q);
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: CozyTheme.of(context)
                      .textSecondary
                      .withValues(alpha: 0.1))),
          color: _selectedPreviewQuestion?.id == q.id
              ? CozyTheme.of(context).primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: _selectedIds.contains(q.id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(q.id);
                    } else {
                      _selectedIds.remove(q.id);
                    }
                  });
                },
              ),
            ),
            SizedBox(
                width: 50,
                child: Center(
                    child: Text(q.id.toString(),
                        style: const TextStyle(fontSize: 12)))),
            Expanded(
              flex: textFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(q.text ?? '(No text)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
            _buildFlexCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: CozyTheme.of(context).background,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _getReadableType(q.type ?? 'unknown'),
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
              typeFlex,
              center: true,
            ),
            _buildFlexCell(
                Text(
                  q.topicNameEn ?? q.topicNameHu ?? '-',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                sectionFlex,
                center: true),
            _buildFlexCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text("L${q.bloomLevel}",
                    style: TextStyle(
                        color: CozyTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
              bloomFlex,
              center: true,
            ),
            _buildFlexCell(
                Text(q.attempts.toString(),
                    style: const TextStyle(fontSize: 12)),
                attemptsFlex,
                center: true),
            _buildFlexCell(
              Text(
                "${accuracy.toStringAsFixed(1)}%",
                style: TextStyle(
                    color: accuracyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              accuracyFlex,
              center: true,
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () => showQuestionEditor(q),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _confirmDelete(q),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildECGTable(StatsProvider stats) {
    if (stats.isLoading && stats.ecgCases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stats.ecgCases.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.adminNoEcgCasesFound,
              style: TextStyle(color: CozyTheme.of(context).textSecondary)));
    }

    return Column(
      children: [
        // Header
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 60,
                  child: Center(
                      child: Text(AppLocalizations.of(context)!.adminTableId,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)))),
              Expanded(
                  flex: 2,
                  child: Text(AppLocalizations.of(context)!.adminTableImage,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text(AppLocalizations.of(context)!.adminTableDiagnosis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(
                  flex: 1,
                  child: Center(
                      child: Text(AppLocalizations.of(context)!.adminTableDifficulty,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)))),
              SizedBox(
                  width: 80,
                  child: Center(
                      child: Text(AppLocalizations.of(context)!.adminTableActions,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)))),
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
                            color: CozyTheme.of(context)
                                .textSecondary
                                .withValues(alpha: 0.1)))),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60, child: Center(child: Text(c.id.toString()))),
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
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.diagnosisCode ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(c.diagnosisName ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: CozyTheme.of(context).textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        )),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.difficulty == 'beginner'
                                ? CozyTheme.of(context)
                                    .success
                                    .withValues(alpha: 0.1)
                                : (c.difficulty == 'advanced'
                                    ? CozyTheme.of(context)
                                        .error
                                        .withValues(alpha: 0.1)
                                    : CozyTheme.of(context)
                                        .primary
                                        .withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c.difficulty.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: c.difficulty == 'beginner'
                                    ? CozyTheme.of(context).success
                                    : (c.difficulty == 'advanced'
                                        ? CozyTheme.of(context).error
                                        : CozyTheme.of(context).primary),
                              )),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 18),
                            onPressed: () => showECGEditor(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                            onPressed: () => _confirmDeleteECG(c),
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

  Widget _buildFlexHeaderCell(String label, int flex,
      {String? sortKey, bool center = false}) {
    final bool isSorted = _sortBy == sortKey;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortKey != null
            ? () => _onSort(sortKey, !isSorted || !_isAscending)
            : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                center ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSorted
                        ? CozyTheme.of(context, listen: false).primary
                        : CozyTheme.of(context, listen: false).textSecondary,
                  ),
                ),
              ),
              if (sortKey != null) ...[
                const SizedBox(width: 2),
                Icon(
                  isSorted
                      ? (_isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 12,
                  color: isSorted
                      ? CozyTheme.of(context, listen: false).primary
                      : Colors.grey[300],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexCell(Widget child, int flex, {bool center = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  String _getReadableType(String type) {
    switch (type) {
      case 'single_choice':
        return 'SCQ';
      case 'relation_analysis':
        return 'RA';
      case 'true_false':
        return 'T/F';
      case 'matching':
        return 'Matching';
      case 'multiple_choice':
        return 'MCQ';
      default:
        return type;
    }
  }

  Widget _buildPaginationFooter(StatsProvider stats) {
    final palette = CozyTheme.of(context);
    final total = stats.adminTotalQuestions;
    const pageSize =
        200; // Match backend limit in quizController.js or stats_provider fetch
    final totalPages = (total / pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
            top: BorderSide(
                color: palette.textSecondary.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _refresh();
                  }
                : null,
          ),
          Text(
            "Page $_currentPage of $totalPages",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _refresh();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void showQuestionEditor(AdminQuestion? q) {
    showDialog(
      context: context,
      builder: (context) => QuestionEditorDialog(
        question: q,
        topics: Provider.of<StatsProvider>(context, listen: false).topics,
        onSaved: () {
          _refresh();
        },
      ),
    );
  }

  void _confirmDelete(AdminQuestion q) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteQuestion),
        content: Text(AppLocalizations.of(context)!.adminConfirmDeleteQuestion(q.id.toString())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                final success =
                    await Provider.of<StatsProvider>(context, listen: false)
                        .deleteQuestion(q.id);
                if (!context.mounted) return;
                if (success) {
                  _refresh();
                  Navigator.pop(context);
                   ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.success)));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.adminErrorQuestionDeleteLinked)));
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void showECGEditor(ECGCase? c) {
    showDialog(
      context: context,
      builder: (context) => ECGEditorDialog(
        ecgCase: c,
        onSaved: () => _refresh(),
      ),
    );
  }

  Widget _buildPreviewPanel(AdminQuestion q) {
    final palette = CozyTheme.of(context);
    final wrongAnswers = []; // Placeholder

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: palette.textSecondary.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(AppLocalizations.of(context)!.adminQuestionDetails,
                          style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary)),
                      Text("#${q.id} • ${q.type}",
                          style: GoogleFonts.quicksand(
                              fontSize: 12, color: palette.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.textSecondary),
                  onPressed: () =>
                      setState(() => _selectedPreviewQuestion = null),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text
                   Text(AppLocalizations.of(context)!.questionText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textSecondary,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                   Text(q.text ?? '(${AppLocalizations.of(context)!.adminUntitled})',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: palette.textPrimary,
                          height: 1.4)),
                  const SizedBox(height: 24),

                  // Stats Removed (visible in table)

                  // Common Knowledge Gap
                   Text(AppLocalizations.of(context)!.adminCommonKnowledgeGap,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textSecondary,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  if (q.successRate < 50) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: palette.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: palette.error, size: 20),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .adminHighFailureRateWarning,
                              style:
                                  TextStyle(color: palette.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // TODO: Wire up to actual answer analytics data
                  if (wrongAnswers.isNotEmpty) ...[
                     Text(AppLocalizations.of(context)!.adminCommonlyConfusedWith,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: palette.textSecondary,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: wrongAnswers
                          .map((ans) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: palette.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: palette.textSecondary
                                            .withValues(alpha: 0.2))),
                                child: Text(ans.toString(),
                                    style: TextStyle(
                                        color: palette.textPrimary,
                                        fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 32),
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showQuestionEditor(q),
                      icon: const Icon(Icons.edit),
                       label: Text(AppLocalizations.of(context)!.adminEditQuestion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.textInverse,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteECG(ECGCase c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.adminConfirmDeleteECG(c.id.toString())),
        content: Text(AppLocalizations.of(context)!.adminConfirmDeleteECG(c.id.toString())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
              onPressed: () async {
                final success =
                    await Provider.of<StatsProvider>(context, listen: false)
                        .deleteECGCase(c.id);
                if (!context.mounted) return;
                if (success) {
                  _refresh();
                  Navigator.pop(context);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorDeleteFailed)));
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showManageSectionsDialog() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final topic = stats.topics.firstWhere((t) => t['id'] == _currentSubjectId,
        orElse: () => {'name': AppLocalizations.of(context)!.adminSubjectFallback});
    final subjectName =
        topic['name_en']?.toString() ?? topic['name']?.toString() ?? AppLocalizations.of(context)!.adminSubjectFallback;

    showDialog(
      context: context,
      builder: (context) => _ManageSectionsDialog(
        subjectId: _currentSubjectId!,
        subjectName: subjectName,
        onChanged: _refresh,
      ),
    );
  }

  Widget _buildInventoryOverview(StatsProvider stats) {
    final palette = CozyTheme.of(context);
    if (stats.inventorySummary.isEmpty && !stats.isLoading) {
      return Center(child: Text(AppLocalizations.of(context)!.adminNoDataAvailable));
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
            side:
                BorderSide(color: palette.textSecondary.withValues(alpha: 0.1)),
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
                        color: palette.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: palette.primary.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    "${subject['total']} Q",
                    style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            children: [
              ...subject['sections'].map<Widget>((section) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.paperWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: palette.shadowSmall,
                    ),
                    child: ExpansionTile(
                      shape:
                          const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape:
                          const RoundedRectangleBorder(side: BorderSide.none),
                      title: Text(
                          section['name_en']?.toString() ??
                              section['name']?.toString() ??
                              'Unnamed Section',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: palette.textPrimary)),
                      trailing: Text("${section['total']} ${AppLocalizations.of(context)!.adminItems}",
                          style: TextStyle(
                              color: palette.textSecondary, fontSize: 12)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [1, 2, 3, 4].map((level) {
                              final count =
                                  section['bloomCounts'][level.toString()] ?? 0;
                              return _buildBloomStat(level, count);
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

  void _showBatchUploadDialog() async {
    final stats = Provider.of<StatsProvider>(context, listen: false);

    // 1. Initial Prompt Dialog
    final pickNow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminBatchUploadTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminBatchUploadSubtitle),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.adminPreparationLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(l10n.adminPreparationSubtitle,
                            style: const TextStyle(fontSize: 12)),
                        TextButton.icon(
                          onPressed: () => stats.downloadQuestionsTemplate(),
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(l10n.adminDownloadTemplate),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminChooseFile),
          ),
        ],
      ),
    );

    if (pickNow != true) return;

    // 2. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result == null || !mounted) return;

    // 3. Process Upload
    final fileName = result.files.single.name;
    final bytes = result.files.single.bytes;

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorReadBytes)));
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isProcessing = true;
            String? errorMsg;
            int? successCount;

            final stats = Provider.of<StatsProvider>(context, listen: false);

            // Start upload immediately
            Future.microtask(() async {
              final uploadResult =
                  await stats.uploadQuestionsBatch(bytes, fileName);

              if (mounted) {
                setDialogState(() {
                  isProcessing = false;
                  if (uploadResult == null) {
                    errorMsg = "Server error or invalid file format.";
                  } else {
                    successCount = uploadResult['message'] != null
                        ? int.tryParse(uploadResult['message'].split(' ')[2])
                        : 0;
                    if (uploadResult['errors'] != null) {
                      errorMsg =
                          "Partial success with errors: \n${(uploadResult['errors'] as List).take(3).join('\n')}";
                    }
                  }
                });
              }
            });

            return AlertDialog(
              title: Text(isProcessing
                  ? l10n.adminProcessingUpload
                  : (errorMsg != null && successCount == null
                      ? l10n.adminUploadFailed
                      : l10n.adminUploadComplete)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing) ...[
                    Text("${l10n.adminParsing} $fileName..."),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ] else ...[
                    if (successCount != null) ...[
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text(l10n.adminUploadSuccess(successCount!),
                          textAlign: TextAlign.center),
                    ],
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMsg!,
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ],
                ],
              ),
              actions: [
                if (!isProcessing)
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Dialog
                        _refresh();
                      },
                      child: Text(l10n.done)),
              ],
            );
          },
        );
      },
    );
  }

  void _onSort(String sortKey, bool ascending) {
    setState(() {
      if (_sortBy == sortKey) {
        _isAscending = ascending;
      } else {
        _sortBy = sortKey;
        _isAscending = ascending;
      }
    });
    _refresh();
  }

  Widget _buildBloomStat(int level, int count) {
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
                  color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text("L$level",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        Text("$count", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _buildBulkActionToolbar(StatsProvider stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: CozyTheme.of(context).primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: CozyTheme.of(context).primary, size: 20),
          const SizedBox(width: 12),
            Text(
              l10n.adminItemsSelected(_selectedIds.length),
            style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: CozyTheme.of(context).primary),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: Text(l10n.adminClearSelection),
          ),
          const VerticalDivider(width: 20, indent: 8, endIndent: 8),
          ElevatedButton.icon(
            onPressed: () => _handleBulkMove(stats),
            icon: const Icon(Icons.drive_file_move, size: 18),
            label: Text(l10n.adminMoveTo),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _handleBulkDelete(stats),
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

  void _handleBulkDelete(StatsProvider stats) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminConfirmBatchDelete),
        content: Text(
            l10n.adminConfirmBatchDeleteSubtitle(_selectedIds.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.adminDeleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await stats.bulkActionQuestions(
          action: 'delete', ids: _selectedIds.toList());
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.adminSuccessDeletedCount(_selectedIds.length))));
          setState(() => _selectedIds.clear());
          _refresh();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.adminErrorDeleteBulk)));
        }
      }
    }
  }

  void _handleBulkMove(StatsProvider stats) async {
    int? targetId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.adminMoveQuestionsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminMoveQuestionsSubtitle(_selectedIds.length)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: targetId,
                items: stats.topics
                    .map<DropdownMenuItem<int>>((topic) => DropdownMenuItem(
                          value: topic['id'],
                          child: Text(
                              topic['name_en'] ?? topic['name'] ?? 'Untitled'),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => targetId = val),
                decoration: InputDecoration(
                    border: const OutlineInputBorder(), labelText: l10n.adminTargetTopic),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
              onPressed:
                  targetId == null ? null : () => Navigator.pop(context, true),
              child: Text(l10n.adminMoveNow),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && targetId != null) {
      final success = await stats.bulkActionQuestions(
          action: 'move', ids: _selectedIds.toList(), targetTopicId: targetId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adminSuccessQuestionsMoved)));
        setState(() => _selectedIds.clear());
        _refresh();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorMoveQuestions)));
      }
    }
  }
}

// Manage Sections Dialog
class _ManageSectionsDialog extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final VoidCallback onChanged;

  const _ManageSectionsDialog({
    required this.subjectId,
    required this.subjectName,
    required this.onChanged,
  });

  @override
  State<_ManageSectionsDialog> createState() => _ManageSectionsDialogState();
}

class _ManageSectionsDialogState extends State<_ManageSectionsDialog> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameHuController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameHuController.dispose();
    super.dispose();
  }

  Future<void> _createSection() async {
    if (_nameEnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorSectionNameEmpty)),
      );
      return;
    }

    setState(() => _isCreating = true);
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final success = await stats.createTopic(_nameEnController.text.trim(),
        _nameHuController.text.trim(), widget.subjectId);
    setState(() => _isCreating = false);

    if (success) {
      _nameEnController.clear();
      _nameHuController.clear();
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminSuccessSectionCreated)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorSectionCreateFailed)),
        );
      }
    }
  }

  Future<void> _deleteSection(int topicId, String name) async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteSectionTitle),
        content: Text(l10n.adminConfirmDeleteSection(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    String? error = await stats.deleteTopic(topicId);

    // Check for "has questions" error (409 Conflict)
    if (error != null && error.contains("question(s)")) {
      if (!mounted) return;

      final confirmForce = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.adminConfirmDataLossTitle,
              style: const TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error ?? "Unknown error",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(l10n.adminDeleteSectionWarning),
              const SizedBox(height: 12),
              Text(l10n.adminConfirmAction),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.adminYesDeleteEverything,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmForce == true) {
        error = await stats.deleteTopic(topicId, force: true);
      } else {
        return; // User cancelled the second confirmation
      }
    }

    if (error == null) {
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminSuccessSectionDeleted)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${l10n.adminManageSectionsTitle} - ${widget.subjectName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Add Section Input
            TextFormField(
              controller: _nameEnController,
              decoration:
                  CozyTheme.inputDecoration(context, l10n.adminSectionNameEnLabel),
              validator: (val) =>
                  val == null || val.isEmpty ? l10n.adminRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameHuController,
              decoration:
                  CozyTheme.inputDecoration(context, l10n.adminSectionNameHuLabel),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createSection,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add),
                label: Text(l10n.adminAddSection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary,
                  foregroundColor: CozyTheme.of(context).textInverse,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sections List
            // Sections List
            Text(
              l10n.adminExistingSections,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<StatsProvider>(
              builder: (context, stats, _) {
                final sections = stats.topics
                    .where((t) => t['parent_id'] == widget.subjectId)
                    .toList();

                if (sections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.adminNoSectionsYet,
                        style: const TextStyle(color: Colors.grey)),
                  );
                }

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _SectionListTile(
                        section: section,
                        onDelete: () => _deleteSection(section['id'],
                            section['name_en'] ?? section['name']),
                        onRename: (nameEn, nameHu) async {
                          final error = await stats.updateTopic(
                              section['id'], nameEn, nameHu);
                          if (error == null) {
                            widget.onChanged();
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionListTile extends StatefulWidget {
  final Map<String, dynamic> section;
  final VoidCallback onDelete;
  final Function(String, String) onRename;

  const _SectionListTile({
    required this.section,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<_SectionListTile> createState() => _SectionListTileState();
}

class _SectionListTileState extends State<_SectionListTile> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  bool _isEditing = false;
  late TextEditingController _editEnController;
  late TextEditingController _editHuController;
  String _editLang = 'en';

  @override
  void initState() {
    super.initState();
    _editEnController = TextEditingController(
        text: widget.section['name_en'] ?? widget.section['name'] ?? '');
    _editHuController =
        TextEditingController(text: widget.section['name_hu'] ?? '');
  }

  @override
  void dispose() {
    _editEnController.dispose();
    _editHuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: _isEditing
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Stretch to full width
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ChoiceChip(
                      label: const Text("EN"),
                      labelStyle: TextStyle(
                        color: _editLang == 'en'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'en',
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).paperWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: CozyTheme.of(context).primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'en'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU"),
                      labelStyle: TextStyle(
                        color: _editLang == 'hu'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'hu',
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).paperWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: CozyTheme.of(context).primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'hu'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                TextField(
                  controller:
                      _editLang == 'en' ? _editEnController : _editHuController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "${l10n.adminRenameSection} (${_editLang.toUpperCase()})",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: CozyTheme.of(context).primary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: CozyTheme.of(context).primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _isEditing = false),
                    ),
                  ),
                  onSubmitted: (val) {
                    widget.onRename(
                        _editEnController.text, _editHuController.text);
                    setState(() => _isEditing = false);
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.section['name_en'] ?? widget.section['name'] ?? ''),
                if (widget.section['name_hu'] != null &&
                    widget.section['name_hu'].isNotEmpty)
                  Text(
                    widget.section['name_hu'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
      trailing: _isEditing
          ? null // Remove tick icon when editing
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditing = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
    );
  }
}

// --- HELPER CLASSES ---

class MatchingPairControllerGroup {
  final TextEditingController leftEn;
  final TextEditingController leftHu;
  final TextEditingController rightEn;
  final TextEditingController rightHu;

  MatchingPairControllerGroup({
    String leftE = '',
    String leftH = '',
    String rightE = '',
    String rightH = '',
  })  : leftEn = TextEditingController(text: leftE),
        leftHu = TextEditingController(text: leftH),
        rightEn = TextEditingController(text: rightE),
        rightHu = TextEditingController(text: rightH);

  void dispose() {
    leftEn.dispose();
    leftHu.dispose();
    rightEn.dispose();
    rightHu.dispose();
  }
}
