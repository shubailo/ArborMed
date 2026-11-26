import 'components/admin_question_action.dart';
import 'package:arbor_med/core/models/topic_hierarchy.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'components/bulk_action_toolbar.dart';
import 'components/bulk_action_handler.dart';
import 'components/batch_upload_dialog.dart';
import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/features/analytics/models/ecg_case.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import '../../../services/admin_question_provider.dart';
import '../../../services/admin_user_provider.dart';
import '../../../theme/cozy_theme.dart';
import 'ecg_editor_dialog.dart';
import 'components/manage_sections_dialog.dart';
import 'components/question_editor_dialog.dart';
import 'components/questions_filter_bar.dart';
import '../../generated/l10n/app_localizations.dart';
import 'components/inventory_overview.dart';
import 'components/ecg_cases_table.dart';
import 'components/pagination_footer.dart';
import 'components/questions_data_table.dart';
import 'components/question_preview_pane.dart';

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
  Future<Map<String, dynamic>?>? _analyticsFuture;
  Timer? _debounceTimer;
  bool _searchPending = false;

  void _clearTableContext() {
    _debounceTimer?.cancel();
    _searchPending = false;
    _selectedIds.clear();
    _selectedPreviewQuestion = null;
    _analyticsFuture = null;
  }

  @override
  void dispose() {
    _catalog?.removeListener(_catalogChanged);
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Persistent filter state for each subject tab
  final Map<int?, int?> _subjectLastTopic = {};

  // Multi-Selection State
  final Set<int> _selectedIds = {};
  List<AdminQuestion>? _lastRows;
  (int, int)? _lastSession;
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  TopicProvider? _catalog;
  List<Map<String, dynamic>>? _snapshot;
  late TopicHierarchy _hierarchy;
  bool _catalogFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final questions = context.watch<AdminQuestionProvider>();
    if (_lastSession != questions.actionSession) {
      _clearTableContext();
      _currentPage = 1;
      _lastSession = questions.actionSession;
    }
    final rows = questions.adminQuestions;
    if (!questions.questionsLoading && !identical(_lastRows, rows)) {
      _lastRows = rows;
      _selectedIds.retainAll(rows.map((q) => q.id));
      final previewId = _selectedPreviewQuestion?.id;
      _selectedPreviewQuestion = rows.where((q) => q.id == previewId).firstOrNull;
      if (_selectedPreviewQuestion == null) _analyticsFuture = null;
      final lastPage = ((questions.adminTotalQuestions - 1) ~/ 200) + 1;
      if (!questions.questionsFailed && _currentPage > lastPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _searchPending || _selectedType == 'ecg' ||
              questions.questionsLoading || !identical(rows, questions.adminQuestions) ||
              _currentPage <= lastPage) {
            return;
          }
          setState(() {
            _clearTableContext();
            _currentPage = lastPage;
          });
          _refresh();
        });
      }
    }
    final catalog = context.read<TopicProvider>();
    if (identical(catalog, _catalog)) return;
    _catalog?.removeListener(_catalogChanged);
    _catalog = catalog..addListener(_catalogChanged);
    _snapshot = catalog.topics;
    _hierarchy = TopicHierarchy(catalog.topics);
  }

  void _catalogChanged() {
    final catalog = _catalog!;
    if (identical(_snapshot, catalog.topics) &&
        _catalogFailed == catalog.loadFailed) {
      return;
    }
    final previousSubject = _currentSubjectId;
    final previousTopic = _selectedTopicId;
    setState(() {
      _catalogFailed = catalog.loadFailed;
      if (!identical(_snapshot, catalog.topics)) {
        _snapshot = catalog.topics;
        _hierarchy = TopicHierarchy(catalog.topics);
        _subjectLastTopic
            .removeWhere((root, id) => !_hierarchy.containsSection(root, id));
        if (!_hierarchy.roots.contains(_currentSubjectId)) {
          _currentSubjectId = null;
        }
        if (!_hierarchy.containsSection(_currentSubjectId, _selectedTopicId)) {
          _selectedTopicId = null;
        }
      }
      if (previousSubject != _currentSubjectId ||
          previousTopic != _selectedTopicId) {
        _clearTableContext();
        _currentPage = 1;
      }
    });
    if (previousSubject != _currentSubjectId ||
        previousTopic != _selectedTopicId) {
      _refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _catalog!.fetchTopics();
      _refresh();
    });
  }

  void _refresh() {
    if (!mounted) return;
    final questionProvider =
        Provider.of<AdminQuestionProvider>(context, listen: false);

    // Determine which topic ID to use:
    // - If a section is selected (_selectedTopicId), use that
    // - Otherwise, if a subject tab is active (_currentSubjectId), use that
    // - Otherwise, null (show all)
    final effectiveTopicId = _selectedTopicId ?? _currentSubjectId;

    debugPrint(
        ' [AdminQuestions] Refresh: Subject=$_currentSubjectId, Topic=$_selectedTopicId, Effective=$effectiveTopicId, Type=$_selectedType');

    if (_selectedType == 'ecg') {
      questionProvider.fetchECGCases();
      // Also fetch diagnoses for the dropdowns
      questionProvider.fetchECGDiagnoses();
    } else {
      questionProvider.fetchAdminQuestions(
        page: _currentPage,
        search: _searchController.text,
        type: _selectedType,
        topicId: effectiveTopicId,
        bloomLevel: _selectedBloom,
        sortBy: _sortBy,
        order: _isAscending ? 'ASC' : 'DESC',
      );
    }
    _refreshSummary();
  }

  void _afterBatchWrite() {
    setState(() => _selectedIds.clear());
    _refreshSummary();
  }

  void _refreshSummary() {
    // Fetch inventory summary ONLY if on "All" tab (no subject selected) and no specific filtering
    if (_currentSubjectId == null &&
        _selectedType.isEmpty &&
        _selectedBloom == null &&
        _searchController.text.isEmpty &&
        _selectedTopicId == null) {
      context.read<AdminUserProvider>().fetchInventorySummary();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _clearTableContext();
      _currentPage = 1;
      _searchPending = true;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchPending = false);
      _refresh();
    });
  }

  void showQuestion(AdminQuestion q) {
    setState(() {
      _clearTableContext();
      _currentSubjectId = null;
      _selectedTopicId = _selectedBloom = null;
      _selectedType = '';
      _currentPage = 1;
      _searchController.text = '#${q.id}';
      _selectedPreviewQuestion = q;
      _analyticsFuture = context.read<AdminQuestionProvider>().fetchQuestionAnalytics(q.id);
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32), // Matched Dashboard padding
        child: Consumer<AdminUserProvider>(
          builder: (context, userProvider, child) {
            final questionProvider = context.read<AdminQuestionProvider>();
            final palette = CozyTheme.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Header
                _buildHeader(questionProvider),
                if (_isSelectionMode && !_searchPending &&
                    !questionProvider.questionsLoading && !questionProvider.questionsFailed)
                  _buildBulkActionToolbar(questionProvider),
                const SizedBox(height: 24),

                // 2. Toolbar (Search, Filters, Batch, New)
                if (_catalogFailed)
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: _catalog!.fetchTopics,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.retry))),
                QuestionsFilterBar(
                  hierarchy: _hierarchy,
                  searchController: _searchController,
                  selectedType: _selectedType,
                  selectedBloom: _selectedBloom,
                  selectedTopicId: _selectedTopicId,
                  currentSubjectId: _currentSubjectId,
                  onSearchChanged: _onSearchChanged,
                  onTypeChanged: (val) {
                    setState(() {
                      _clearTableContext();
                      _selectedType = val ?? '';
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                  onBloomChanged: (val) {
                    setState(() {
                      _clearTableContext();
                      _selectedBloom = val;
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                  onTopicChanged: (val) {
                    setState(() {
                      _clearTableContext();
                      _selectedTopicId = val;
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                  onManageSections: () => _showManageSectionsDialog(),
                  onBatchUpload: _showBatchUploadDialog,
                  onNewItem: () => _selectedType == 'ecg'
                      ? showECGEditor(null)
                      : showQuestionEditor(null),
                ),
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
                                  color: palette.textPrimary.withValues(
                                    alpha: 0.05,
                                  ),
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
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child:
                                              (_currentSubjectId == null &&
                                                  _selectedType.isEmpty &&
                                                  _selectedBloom == null &&
                                                  _searchController
                                                      .text
                                                      .isEmpty &&
                                                  _selectedTopicId == null)
                                              ? KeyedSubtree(
                                                  key: const ValueKey(
                                                    'overview',
                                                  ),
                                                  child:
                                                      InventoryOverview(
                                                        inventorySummary:
                                                            userProvider
                                                                .inventorySummary,
                                                        isLoading: userProvider
                                                            .isLoading,
                                                      ),
                                                )
                                              : KeyedSubtree(
                                                  key: ValueKey(
                                                    'table_${_currentSubjectId ?? "all"}_${_selectedTopicId ?? "all"}',
                                                  ),
                                                  child: _selectedType == 'ecg'
                                                      ? ECGCasesTable(
                                                           ecgCases: questionProvider.ecgCases,
                                                           isLoading: questionProvider.ecgCasesLoading,
                                                           onRetry: questionProvider.ecgCasesFailed ? questionProvider.fetchECGCases : null,

                                                           onEditCase: showECGEditor,
                                                           onDeleteCase: _confirmDeleteECG,
                                                         )

                                                      : _searchPending || questionProvider.questionsLoading
                                                        ? const Center(child: CircularProgressIndicator())
                                                        : questionProvider.questionsFailed
                                                          ? Center(child: TextButton.icon(onPressed: _refresh,
                                                              icon: const Icon(Icons.refresh), label: Text(l10n.retry)))
                                                      : (questionProvider
                                                                .adminQuestions
                                                                .isNotEmpty
                                                            ? _buildQuestionTable(questionProvider)
                                                            : Center(
                                                                child: Text(
                                                                  l10n.adminNoDataAvailable,
                                                                  style: GoogleFonts.outfit(
                                                                    color: palette
                                                                        .textSecondary,
                                                                  ),
                                                                ),
                                                              )),
                                                ),
                                        ),
                                      ),

                                      // Loading indicator overlay (Non-blocking)
                                      if (!questionProvider.questionsLoading && (questionProvider.isLoading || userProvider.isLoading)) ...[
                                        (questionProvider.adminQuestions.isEmpty &&
                                                userProvider.inventorySummary.isEmpty)
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
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
                                                        Color
                                                      >(palette.primary),
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
                                  PaginationFooter(
                                    currentPage: _currentPage,
                                    totalCount: questionProvider.adminTotalQuestions,
                                    pageSize: 200, // Matching backend limit
                                    onPageChanged: (page) {
                                      setState(() { _clearTableContext(); _currentPage = page; });
                                      _refresh();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // PREVIEW PANEL (Split View)
                      if (_selectedPreviewQuestion != null && !questionProvider.questionsLoading &&
                          !questionProvider.questionsFailed) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: QuestionPreviewPane(
                            question: _selectedPreviewQuestion!,
                            onReportsChanged: _refresh,
                            analyticsFuture: _analyticsFuture,
                            onClose: () => setState(() => _selectedPreviewQuestion = null),
                            onEditQuestion: showQuestionEditor,
                          ),
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

  Widget _buildHeader(AdminQuestionProvider questionProvider) {
    final l = AppLocalizations.of(context)!;
    final tabs = <Map<String, dynamic>>[
      {'key': 0, 'label': l.quizSubjects, 'type': '', 'topicId': null},
      for (final id in _hierarchy.roots)
        if (_hierarchy.byId[id]!.slug != 'ecg')
          {
            'key': id,
            'label': _hierarchy.label(id, l.localeName, l.adminSubjectFallback),
            'type': '',
            'topicId': id
          },
      {'key': -1, 'label': l.quizECG, 'type': 'ecg', 'topicId': null},
      {
        'key': -2,
        'label': l.adminCaseStudies,
        'type': 'case_study',
        'topicId': null
      },
    ];
    final activeTab = tabs.firstWhere(
      (t) =>
          t['topicId'] == _currentSubjectId &&
          (t['type'] == _selectedType ||
              (t['type'] == '' &&
                  _selectedType != 'ecg' &&
                  _selectedType != 'case_study')),
      orElse: () => tabs.first,
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
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (key) {
                final tab = tabs.where((t) => t['key'] == key).firstOrNull;
                if (tab == null || (key > 0 && !_hierarchy.roots.contains(key))) {
                  return;
                }
                setState(() {
                  _clearTableContext();
                  // 1. Save current selection for previous subject before switching
                  _subjectLastTopic[_currentSubjectId] = _selectedTopicId;

                  _selectedType = tab['type']!;
                  _currentSubjectId = tab['topicId'];

                  // 2. Restore last selection for the new subject
                  _selectedTopicId = _subjectLastTopic[_currentSubjectId];

                  _currentPage = 1;
                });
                _refresh();
              },
              itemBuilder: (context) => tabs.map((entry) {
                return PopupMenuItem<int>(
                  value: entry['key'],
                  child: Text(
                    entry['label'],
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
                  Icon(
                    Icons.expand_more,
                    size: 28,
                    color: CozyTheme.of(context, listen: false).textSecondary,
                  ),
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
        if (_selectedType != 'ecg' || (!questionProvider.ecgCasesLoading && !questionProvider.ecgCasesFailed))
          _buildStatusChip(_selectedType == 'ecg'
              ? l10n.adminEcgCaseCount(questionProvider.ecgCases.length)
              : l10n.adminQuestionCount(questionProvider.adminTotalQuestions)),
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

  void showQuestionEditor(AdminQuestion? q) {
    showDialog(
      context: context,
      builder: (context) => QuestionEditorDialog(
        question: q,
        topics: context.watch<TopicProvider>().topics,
        onSaved: () {
          _refresh();
        },
      ),
    );
  }

  Future<void> _confirmDelete(AdminQuestion q) async {
    final provider = context.read<AdminQuestionProvider>();
    await runQuestionAction(context, provider, (active) async {
      final labels = l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) {
          void close(bool result) {
            if (ModalRoute.of(dialog)?.isCurrent == true) {
              Navigator.pop(dialog, result);
            }
          }
          return AlertDialog(
            title: Text(labels.deleteQuestion),
            content: Text(labels.adminConfirmDeleteQuestion(q.id.toString())),
            actions: [
              TextButton(onPressed: () => close(false), child: Text(labels.cancel)),
              TextButton(onPressed: () => close(true), child: Text(labels.delete)),
            ],
          );
        },
      );
      if (confirmed != true || !active() || _searchPending ||
          provider.questionsLoading || !provider.adminQuestions.any((row) => row.id == q.id)) {
        return;
      }
      final deleted = await provider.deleteQuestion(q.id);
      if (!mounted || !active()) return;
      if (deleted) {
        _refreshSummary();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(deleted ? labels.success : labels.adminErrorQuestionDeleteLinked),
      ));
    });
  }

  void showECGEditor(ECGCase? c) {
    showDialog(
      context: context,
      builder: (context) =>
          ECGEditorDialog(ecgCase: c, onSaved: () => _refresh()),
    );
  }



  void _confirmDeleteECG(ECGCase c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.adminConfirmDeleteECG(c.id.toString()),
        ),
        content: Text(
          AppLocalizations.of(context)!.adminConfirmDeleteECG(c.id.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<AdminQuestionProvider>(
                context,
                listen: false,
              ).deleteECGCase(c.id);
              if (!context.mounted) return;
              if (success) {
                _refresh();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.adminErrorDeleteFailed,
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageSectionsDialog() {
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    final topic = topicProvider.topics.firstWhere(
      (t) => t['id'] == _currentSubjectId,
      orElse: () => {
        'name': AppLocalizations.of(context)!.adminSubjectFallback,
      },
    );
    final subjectName =
        topic['name_en']?.toString() ??
        topic['name']?.toString() ??
        AppLocalizations.of(context)!.adminSubjectFallback;

    showDialog(
      context: context,
      builder: (context) => ManageSectionsDialog(
        subjectId: _currentSubjectId!,
        subjectName: subjectName,
        onChanged: _refresh,
      ),
    );
  }

  void _showBatchUploadDialog() async {
    final questionProvider = Provider.of<AdminQuestionProvider>(context, listen: false);
    await BatchUploadDialog.show(
      context,
      questionProvider: questionProvider,
      onComplete: _afterBatchWrite,
    );
  }
  Widget _buildQuestionTable(AdminQuestionProvider provider) {
    final rows = provider.adminQuestions;
    final session = provider.actionSession;
    bool current() => mounted && !_searchPending && !provider.questionsLoading &&
        !provider.questionsFailed && provider.actionSession == session &&
        identical(rows, provider.adminQuestions);

    return QuestionsDataTable(
      questions: rows,
      selectedIds: _selectedIds,
      onSelectionChanged: (ids) {
        if (!current()) return;
        setState(() {
          _selectedIds.clear();
          _selectedIds.addAll(rows.map((q) => q.id).where(ids.contains));
        });
      },
      sortBy: _sortBy,
      isAscending: _isAscending,
      onSort: (sort, ascending) {
        if (current()) _onSort(sort, ascending);
      },
      selectedPreviewQuestion: _selectedPreviewQuestion,
      onPreviewSelected: (q) {
        if (!current()) return;
        setState(() {
          _selectedPreviewQuestion = q;
          _analyticsFuture = provider.fetchQuestionAnalytics(q.id);
        });
      },
      getReadableType: _getReadableType,
      onEditQuestion: (q) {
        if (current()) showQuestionEditor(q);
      },
      onDeleteQuestion: (q) {
        if (current()) _confirmDelete(q);
      },
    );
  }

  void _onSort(String sortKey, bool ascending) {
    setState(() {
      // The refreshed page reconciles retained selections by question ID.
      _currentPage = 1;
      _sortBy = sortKey;
      _isAscending = ascending;
    });
    _refresh();
  }

  Widget _buildBulkActionToolbar(AdminQuestionProvider questionProvider) {
    return BulkActionToolbar(
      selectedCount: _selectedIds.length,
      onClearSelection: () => setState(() => _selectedIds.clear()),
      onMove: () => BulkActionHandler.handleBulkMove(
        context: context,
        questionProvider: questionProvider,
        selectedIds: Set.of(_selectedIds),
        onSuccess: _afterBatchWrite,
      ),
      onDelete: () => BulkActionHandler.handleBulkDelete(
        context: context,
        questionProvider: questionProvider,
        selectedIds: Set.of(_selectedIds),
        onSuccess: _afterBatchWrite,
      ),
    );
  }
}
