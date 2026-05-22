import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
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

    debugPrint(
        ' [AdminQuestions] Refresh: Subject=$_currentSubjectId, Topic=$_selectedTopicId, Effective=$effectiveTopicId, Type=$_selectedType');

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
      l10n.quizSubjectPharmacology,
    ];

    // Map localized names to stable database slugs
    final subjectSlugs = {
      l10n.quizSubjectPathophysiology: 'pathophysiology',
      l10n.quizSubjectPathology: 'pathology',
      l10n.quizSubjectMicrobiology: 'microbiology',
      l10n.quizSubjectPharmacology: 'pharmacology',
    };

    final stats = Provider.of<StatsProvider>(context, listen: false);
    setState(() {
      _tabs = [
        {'label': l10n.quizSubjects, 'type': '', 'topicId': null},
        ...subjects.map((name) {
          final slug = subjectSlugs[name];
          final t = stats.topics.firstWhere(
            (topic) =>
                (topic['slug']?.toString() == slug) ||
                (topic['name_en']?.toString() == name) ||
                (topic['name_hu']?.toString() == name) ||
                (topic['name']?.toString() == name),
            orElse: () => {'id': null},
          );
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
                QuestionsFilterBar(
                  searchController: _searchController,
                  selectedType: _selectedType,
                  selectedBloom: _selectedBloom,
                  selectedTopicId: _selectedTopicId,
                  currentSubjectId: _currentSubjectId,
                  onSearchChanged: _onSearchChanged,
                  onTypeChanged: (val) {
                    setState(() {
                      _selectedType = val ?? '';
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                  onBloomChanged: (val) {
                    setState(() => _selectedBloom = val);
                    _refresh();
                  },
                  onTopicChanged: (val) {
                    setState(() {
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
                                                        stats: stats,
                                                      ),
                                                )
                                              : KeyedSubtree(
                                                  key: ValueKey(
                                                    'table_${_currentSubjectId ?? "all"}_${_selectedTopicId ?? "all"}',
                                                  ),
                                                  child: _selectedType == 'ecg'
                                                      ? ECGCasesTable(
                                                           stats: stats,
                                                           onEditCase: showECGEditor,
                                                           onDeleteCase: _confirmDeleteECG,
                                                         )

                                                      : (stats
                                                                .adminQuestions
                                                                .isNotEmpty
                                                            ? QuestionsDataTable(
                                                                stats: stats,
                                                                selectedIds: _selectedIds,
                                                                onSelectionChanged: (ids) {
                                                                  setState(() {
                                                                    _selectedIds.clear();
                                                                    _selectedIds.addAll(ids);
                                                                  });
                                                                },
                                                                sortBy: _sortBy,
                                                                isAscending: _isAscending,
                                                                onSort: _onSort,
                                                                selectedPreviewQuestion: _selectedPreviewQuestion,
                                                                onPreviewSelected: (q) {
                                                                  setState(() {
                                                                    _selectedPreviewQuestion = q;
                                                                    _analyticsFuture = Provider.of<StatsProvider>(
                                                                      context,
                                                                      listen: false,
                                                                    ).fetchQuestionAnalytics(q.id);
                                                                  });
                                                                },
                                                                getReadableType: _getReadableType,
                                                                onEditQuestion: showQuestionEditor,
                                                                onDeleteQuestion: _confirmDelete,
                                                              )
                                                            : Center(
                                                                child: Text(
                                                                  "No questions found.",
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
                                      if (stats.isLoading) ...[
                                        (stats.adminQuestions.isEmpty &&
                                                stats.inventorySummary.isEmpty)
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
                                    totalCount: stats.adminTotalQuestions,
                                    pageSize: 200, // Matching backend limit
                                    onPageChanged: (page) {
                                      setState(() => _currentPage = page);
                                      _refresh();
                                    },
                                  ),
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
                          child: QuestionPreviewPane(
                            question: _selectedPreviewQuestion!,
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
                borderRadius: BorderRadius.circular(16),
              ),
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
        _buildStatusChip(
          "${stats.adminTotalQuestions} ${l10n.adminQuestionsSmall}",
        ),
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
        content: Text(
          AppLocalizations.of(
            context,
          )!.adminConfirmDeleteQuestion(q.id.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(
                context,
                listen: false,
              ).deleteQuestion(q.id);
              if (!context.mounted) return;
              if (success) {
                _refresh();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.success),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.adminErrorQuestionDeleteLinked,
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
              final success = await Provider.of<StatsProvider>(
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
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final topic = stats.topics.firstWhere(
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
                        Text(
                          l10n.adminPreparationLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.adminPreparationSubtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: () => stats.downloadQuestionsTemplate(),
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(l10n.adminDownloadTemplate),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
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
            child: const Text("Cancel"),
          ),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminErrorReadBytes),
          ),
        );
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
              final uploadResult = await stats.uploadQuestionsBatch(
                bytes,
                fileName,
              );

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
              title: Text(
                isProcessing
                    ? l10n.adminProcessingUpload
                    : (errorMsg != null && successCount == null
                          ? l10n.adminUploadFailed
                          : l10n.adminUploadComplete),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing) ...[
                    Text("${l10n.adminParsing} $fileName..."),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ] else ...[
                    if (successCount != null) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.adminUploadSuccess(successCount!),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
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
                    child: Text(l10n.done),
                  ),
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

  Widget _buildBulkActionToolbar(StatsProvider stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CozyTheme.of(context).primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: CozyTheme.of(context).primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.adminItemsSelected(_selectedIds.length),
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: CozyTheme.of(context).primary,
            ),
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
          l10n.adminConfirmBatchDeleteSubtitle(_selectedIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
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
        action: 'delete',
        ids: _selectedIds.toList(),
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.adminSuccessDeletedCount(_selectedIds.length)),
            ),
          );
          setState(() => _selectedIds.clear());
          _refresh();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.adminErrorDeleteBulk),
            ),
          );
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
                    .map<DropdownMenuItem<int>>(
                      (topic) => DropdownMenuItem(
                        value: topic['id'],
                        child: Text(
                          topic['name_en'] ?? topic['name'] ?? 'Untitled',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => targetId = val),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.adminTargetTopic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: targetId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l10n.adminMoveNow),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && targetId != null) {
      final success = await stats.bulkActionQuestions(
        action: 'move',
        ids: _selectedIds.toList(),
        targetTopicId: targetId,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.adminSuccessQuestionsMoved,
            ),
          ),
        );
        setState(() => _selectedIds.clear());
        _refresh();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.adminErrorMoveQuestions,
            ),
          ),
        );
      }
    }
  }
}
