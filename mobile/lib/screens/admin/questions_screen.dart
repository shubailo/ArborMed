import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/stats_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import 'ecg_editor_dialog.dart';
import 'components/question_editor_dialog.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
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
    if (_currentSubjectId == null && _selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null) {
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
    final provider = Provider.of<StatsProvider>(context, listen: false);
    final subjects = ['Pathophysiology', 'Pathology', 'Microbiology', 'Pharmacology'];
    
    setState(() {
      _tabs = [
        {'label': 'All', 'type': '', 'topicId': null},
        ...subjects.map((name) {
          final t = provider.topics.firstWhere(
            (topic) => (topic['name_en']?.toString() == name) || (topic['name']?.toString() == name), 
            orElse: () => {'id': null}
          );
          return {
            'label': name,
            'type': '', // Empty type - filter by topicId only
            'topicId': t['id'],
          };
        }),
        {'label': 'ECG', 'type': 'ecg', 'topicId': null},
        {'label': 'Case', 'type': 'case_study', 'topicId': null},
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Header
                _buildHeader(stats),
                const SizedBox(height: 24),
                
                // 2. Toolbar (Search, Filters, Batch, New)
                _buildToolbar(stats),
                const SizedBox(height: 24),
                  
                  Expanded(
                    child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CozyTheme.shadowSmall,
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
                                  duration: const Duration(milliseconds: 300),
                                  child: (_currentSubjectId == null && _selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null)
                                    ? KeyedSubtree(
                                        key: const ValueKey('overview'),
                                        child: _buildInventoryOverview(stats),
                                      )
                                    : KeyedSubtree(
                                        key: ValueKey('table_${_currentSubjectId ?? "all"}_${_selectedTopicId ?? "all"}'),
                                        child: _selectedType == 'ecg' 
                                            ? _buildECGTable(stats) 
                                            : (stats.adminQuestions.isNotEmpty 
                                                ? _buildTable(stats)
                                                : Center(child: Text("No questions found.", style: TextStyle(color: Colors.grey[400])))),
                                      ),
                                ),
                              ),
                              
                              // Loading indicator overlay (Non-blocking)
                              if (stats.isLoading) ...[
                                (stats.adminQuestions.isEmpty && stats.inventorySummary.isEmpty) 
                                  ? const Center(child: CircularProgressIndicator())
                                  : const Positioned(
                                      top: 0, left: 0, right: 0,
                                      child: LinearProgressIndicator(minHeight: 3),
                                    ),
                              ],
                            ],
                          ),
                        ),
                        // Pagination Footer
                        if (_selectedType != 'ecg' && !(_currentSubjectId == null && _selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null))
                          _buildPaginationFooter(stats),
                      ],
                    ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (index) {
                setState(() {
                  _selectedType = _tabs[index]['type']!;
                  _currentSubjectId = _tabs[index]['topicId'];
                  _selectedTopicId = null;
                  _currentPage = 1;
                });
                _refresh();
              },
              itemBuilder: (context) => _tabs.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value['label'], style: GoogleFonts.quicksand(color: CozyTheme.textPrimary)),
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
                      color: CozyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, size: 28, color: CozyTheme.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Question Bank Management",
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: CozyTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Stats Chip
        _buildStatusChip("${stats.adminTotalQuestions} Questions"),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CozyTheme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CozyTheme.shadowSmall,
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 13,
          color: CozyTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToolbar(StatsProvider stats) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search questions or topics...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged, // NEW
          ),
        ),
        // Topic Filter (only show when a subject tab is active)
        if (_currentSubjectId != null) const SizedBox(width: 8),
        if (_currentSubjectId != null)
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              // Filter topics to show only sections of the current subject
              final subjectSections = stats.topics.where((topic) {
                return topic['parent_id'] == _currentSubjectId;
              }).toList();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<int?>(
                  value: _selectedTopicId,
                  hint: const Text("All Sections"),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Sections")),
                    ...subjectSections.map((topic) => DropdownMenuItem(
                      value: topic['id'] as int,
                      child: Text(topic['name_en']?.toString() ?? topic['name']?.toString() ?? 'Unnamed Section'),
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
              );
            },
          ),
        if (_currentSubjectId != null) const SizedBox(width: 8),
        if (_currentSubjectId != null)
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: "Manage Sections",
            onPressed: () => _showManageSectionsDialog(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const SizedBox(width: 16),
        // Bloom Filter
        // Bloom Filter (Only show if filtering by Subject or Type)
        if (_currentSubjectId != null || _selectedType.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200), // Clean border
            ),
            child: DropdownButton<int?>(
              value: _selectedBloom,
              hint: const Text("All Levels"),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: [
                const DropdownMenuItem(value: null, child: Text("All Levels")),
                ...[1, 2, 3, 4].map((l) => DropdownMenuItem(value: l, child: Text("Level $l"))),
              ],
              onChanged: (val) {
                setState(() => _selectedBloom = val);
                _refresh();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.upload_file, size: 20),
          tooltip: "Batch Upload",
          onPressed: _showBatchUploadDialog,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: CozyTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _selectedType == 'ecg' ? _showECGEditDialog(null) : _showEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(_selectedType == 'ecg' ? "New ECG" : "New Question"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CozyTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
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
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 60, child: Center(child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                  _buildFlexHeaderCell("Question Text", textFlex),
                  _buildFlexHeaderCell("Type", typeFlex, center: true),
                  _buildFlexHeaderCell("Section", sectionFlex, sortKey: 'topic_name', center: true),
                  _buildFlexHeaderCell("Bloom", bloomFlex, sortKey: 'bloom_level', center: true),
                  _buildFlexHeaderCell("Attempts", attemptsFlex, sortKey: 'attempts', center: true),
                  _buildFlexHeaderCell("Accuracy", accuracyFlex, sortKey: 'success_rate', center: true),
                  const SizedBox(width: 80, child: Center(child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                ],
              ),
            ),
            // 2. SCROLLABLE BODY
            Expanded(
              child: ListView.builder(
                itemCount: stats.adminQuestions.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final q = stats.adminQuestions[index];
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
                        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        color: _selectedPreviewQuestion?.id == q.id ? Colors.blue.withValues(alpha: 0.1) : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 60, child: Center(child: Text(q.id.toString(), style: const TextStyle(fontSize: 12)))),
                          Expanded(
                            flex: textFlex,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(q.text ?? '(No text)', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          _buildFlexCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                _getReadableType(q.type ?? 'unknown'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
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
                            center: true
                          ),
                          _buildFlexCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                              child: Text("L${q.bloomLevel}", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            bloomFlex,
                            center: true,
                          ),
                          _buildFlexCell(Text(q.attempts.toString(), style: const TextStyle(fontSize: 12)), attemptsFlex, center: true),
                          _buildFlexCell(
                            Text(
                              "${accuracy.toStringAsFixed(1)}%",
                              style: TextStyle(color: accuracyColor, fontWeight: FontWeight.bold, fontSize: 12),
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
                                  onPressed: () => _showEditDialog(q),
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
                },
              ),
            ),
            const SizedBox(height: 8), // Reduced bottom padding
          ],
        );
      },
    );
  }

  Widget _buildECGTable(StatsProvider stats) {
    if (stats.isLoading && stats.ecgCases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stats.ecgCases.isEmpty) {
      return Center(child: Text("No ECG cases found.", style: TextStyle(color: Colors.grey[400])));
    }

    return Column(
      children: [
        // Header
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 60, child: Center(child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
              Expanded(flex: 2, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Diagnosis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Center(child: Text("Difficulty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
              SizedBox(width: 80, child: Center(child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
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
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Center(child: Text(c.id.toString()))),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          c.imageUrl.startsWith('http') ? c.imageUrl : '${ApiService.baseUrl}${c.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.diagnosisCode ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(c.diagnosisName ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      )
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.difficulty == 'beginner' ? Colors.green[50] : (c.difficulty == 'advanced' ? Colors.red[50] : Colors.blue[50]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c.difficulty.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                            onPressed: () => _showECGEditDialog(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
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

  Widget _buildFlexHeaderCell(String label, int flex, {String? sortKey, bool center = false}) {
    final bool isSorted = _sortBy == sortKey;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortKey != null ? () => _onSort(sortKey, !isSorted || !_isAscending) : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSorted ? CozyTheme.primary : Colors.grey[600]
                  ),
                ),
              ),
              if (sortKey != null) ...[
                const SizedBox(width: 2),
                Icon(
                  isSorted ? (_isAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
                  size: 12,
                  color: isSorted ? CozyTheme.primary : Colors.grey[300],
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
      case 'single_choice': return 'Single Choice';
      case 'relation_analysis': return 'Relation Analysis';
      case 'true_false': return 'True/False';
      case 'matching': return 'Matching';
      case 'case_study': return 'Case Study';
      case 'ecg': return 'ECG';
      default: return type;
    }
  }

  Widget _buildPaginationFooter(StatsProvider stats) {
    final total = stats.adminTotalQuestions;
    const pageSize = 200; // Match backend limit in quizController.js or stats_provider fetch
    final totalPages = (total / pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () {
              setState(() => _currentPage--);
              _refresh();
            } : null,
          ),
          Text(
            "Page $_currentPage of $totalPages",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages ? () {
              setState(() => _currentPage++);
              _refresh();
            } : null,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(AdminQuestion? q) {
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
        title: const Text("Delete Question?"),
        content: Text("Are you sure you want to delete question #${q.id}? This cannot be undone if students have already answered it (soft-delete coming soon)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(context, listen: false).deleteQuestion(q.id);
              if (!context.mounted) return;
              if (success) {
                _refresh();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted.")));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot delete: Question has linked responses.")));
                 Navigator.pop(context);
              }
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showECGEditDialog(ECGCase? c) {
    showDialog(
      context: context,
      builder: (context) => ECGEditorDialog(
        ecgCase: c,
        onSaved: () => _refresh(),
      ),
    );
  }

  void _confirmDeleteECG(ECGCase c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete ECG Case?"),
        content: Text("Are you sure you want to delete ECG #${c.id}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
             onPressed: () async {
               final success = await Provider.of<StatsProvider>(context, listen: false).deleteECGCase(c.id);
               if (!context.mounted) return;
               if (success) {
                 _refresh();
                 Navigator.pop(context);
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
                 Navigator.pop(context);
               }
             },
             child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showManageSectionsDialog() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final topic = stats.topics.firstWhere(
      (t) => t['id'] == _currentSubjectId, 
      orElse: () => {'name': 'Subject'}
    );
    final subjectName = topic['name_en']?.toString() ?? topic['name']?.toString() ?? 'Subject';
    
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
    if (stats.inventorySummary.isEmpty && !stats.isLoading) {
      return const Center(child: Text("No data available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stats.inventorySummary.length,
      itemBuilder: (context, index) {
        final subject = stats.inventorySummary[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Row(
              children: [
                Text(subject['name_en']?.toString() ?? subject['name']?.toString() ?? 'Unnamed Subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50, // Greenish background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Text(
                    "${subject['total']} Q", // Uppercase Q
                    style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            children: [
              ...subject['sections'].map<Widget>((section) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      title: Text(section['name_en']?.toString() ?? section['name']?.toString() ?? 'Unnamed Section', style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text("${section['total']} items", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [1, 2, 3, 4].map((level) {
                              final count = section['bloomCounts'][level.toString()] ?? 0;
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
    // 1. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || !mounted) return;

    // 2. Show Confirm/Processing Dialog
    final fileName = result.files.single.name;
    // Note: On web, use bytes. On mobile, use path.
    // For now, we'll just simulate the read.

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Processing Upload"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text("Parsing $fileName..."),
               const SizedBox(height: 16),
               const LinearProgressIndicator(),
               const SizedBox(height: 16),
               const Text("This is a simulation. Backend integration required for real processing.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
             TextButton(
               onPressed: () => Navigator.pop(context), 
               child: const Text("Cancel")
             ),
             TextButton(
               onPressed: () {
                 Navigator.pop(context); // Close Dialog
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload simulated successfully.")));
                 _refresh(); // Refresh list to see any (fake) changes
               },
               child: const Text("Done Uploading")
             ),
          ],
        );
      },
    );
  }


  Widget _buildBloomStat(int level, int count) {
    Color color;
    String label;
    switch (level) {
      case 1: color = Colors.green; label = "R"; break; // Remember
      case 2: color = Colors.blue; label = "U"; break; // Understand
      case 3: color = Colors.orange; label = "Ap"; break; // Apply
      case 4: color = Colors.red; label = "An"; break; // Analyze
      default: color = Colors.grey; label = "L"; break;
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
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text("L$level", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        Text("$count", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
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
        const SnackBar(content: Text("English Section name cannot be empty")),
      );
      return;
    }

    setState(() => _isCreating = true);
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final success = await stats.createTopic(
      _nameEnController.text.trim(), 
      _nameHuController.text.trim(), 
      widget.subjectId
    );
    setState(() => _isCreating = false);

    if (success) {
      _nameEnController.clear();
      _nameHuController.clear();
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Section created successfully")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create section")),
        );
      }
    }
  }

  Future<void> _deleteSection(int topicId, String name) async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Section"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
          title: const Text("Confirm Data Loss", style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error ?? "Unknown error", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Deleting this section will PERMANENTLY delete all questions within it. This action cannot be undone."),
              const SizedBox(height: 12),
              const Text("Are you absolutely sure?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("YES, DELETE EVERYTHING", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          const SnackBar(content: Text("Section deleted successfully")),
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
              "Manage Sections - ${widget.subjectName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),


            // Add Section Input
            TextFormField(
              controller: _nameEnController,
              decoration: CozyTheme.inputDecoration("Section Name (EN)"),
              validator: (val) => val == null || val.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameHuController,
              decoration: CozyTheme.inputDecoration("Section Name (HU)"),
            ),
            const SizedBox(height: 16),
            
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createSection,
                icon: _isCreating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
                label: const Text("Add Section"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sections List
            const Text(
              "Existing Sections",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<StatsProvider>(
              builder: (context, stats, _) {
                final sections = stats.topics.where((t) => t['parent_id'] == widget.subjectId).toList();
                
                if (sections.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No sections yet. Create one above!", style: TextStyle(color: Colors.grey)),
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
                        onDelete: () => _deleteSection(section['id'], section['name_en'] ?? section['name']),
                        onRename: (nameEn, nameHu) async {
                           final error = await stats.updateTopic(section['id'], nameEn, nameHu);
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
                child: const Text("Close"),
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
  bool _isEditing = false;
  late TextEditingController _editEnController;
  late TextEditingController _editHuController;
  String _editLang = 'en';

  @override
  void initState() {
    super.initState();
    _editEnController = TextEditingController(text: widget.section['name_en'] ?? widget.section['name'] ?? '');
    _editHuController = TextEditingController(text: widget.section['name_hu'] ?? '');
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
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch to full width
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ChoiceChip(
                      label: const Text("EN"),
                      labelStyle: TextStyle(
                        color: _editLang == 'en' ? Colors.white : CozyTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'en',
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: CozyTheme.primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'en'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU"),
                      labelStyle: TextStyle(
                        color: _editLang == 'hu' ? Colors.white : CozyTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'hu',
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: CozyTheme.primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'hu'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                TextField(
                  controller: _editLang == 'en' ? _editEnController : _editHuController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Rename Section (${_editLang.toUpperCase()})",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: CozyTheme.primary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: CozyTheme.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                       icon: const Icon(Icons.close, size: 16),
                       onPressed: () => setState(() => _isEditing = false),
                    ),
                  ),
                  onSubmitted: (val) {
                    widget.onRename(_editEnController.text, _editHuController.text);
                    setState(() => _isEditing = false);
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.section['name_en'] ?? widget.section['name'] ?? ''),
                if (widget.section['name_hu'] != null && widget.section['name_hu'].isNotEmpty)
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
