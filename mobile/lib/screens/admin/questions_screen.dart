import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_guard.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import 'dart:convert';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({Key? key}) : super(key: key);

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
    provider.fetchAdminQuestions(
      page: _currentPage, 
      search: _searchController.text,
      type: _selectedType,
      topicId: effectiveTopicId,
      bloomLevel: _selectedBloom,
      sortBy: _sortBy,
      order: _isAscending ? 'ASC' : 'DESC',
    );
    
    // Fetch inventory summary if on "All" tab and no specific filtering
    if (_selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null) {
      provider.fetchInventorySummary();
    }
    
    // 2. Fetch Topics if tabs are empty
    if (_tabs.isEmpty) {
      provider.fetchTopics().then((_) {
        if (mounted) _buildDynamicTabs();
      });
    }
  }

  void _buildDynamicTabs() {
    final provider = Provider.of<StatsProvider>(context, listen: false);
    final subjects = ['Pathophysiology', 'Pathology', 'Microbiology', 'Pharmacology'];
    
    setState(() {
      _tabs = [
        {'label': 'All', 'type': '', 'topicId': null},
        ...subjects.map((name) {
          final t = provider.topics.firstWhere((topic) => topic['name'] == name, orElse: () => {'id': null});
          return {
            'label': name,
            'type': t['id'] != null ? 'single_choice' : '', // Fallback
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

    return AdminGuard(
      child: DefaultTabController(
        length: _tabs.length,
        child: AdminScaffold(
          title: "",
          showHeader: false, // New parameter
          activeRoute: '/admin/questions',
          child: Consumer<StatsProvider>(
            builder: (context, stats, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs
                  _buildTabs(),
                  const SizedBox(height: 16),
                  
                  // Toolbar
                  _buildToolbar(stats),
                  const SizedBox(height: 24),
                  
                  // Table
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: CozyTheme.shadowSmall,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 1. Show Inventory Overview if on "All" tab and no specific filters
                          if (_selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null)
                            Positioned.fill(child: _buildInventoryOverview(stats))
                          
                          // 2. Otherwise show the standard table
                          else if (stats.adminQuestions.isNotEmpty)
                            Positioned.fill(child: _buildTable(stats)),
                          
                          // Loading indicator overlay (Non-blocking)
                          if (stats.isLoading)
                            (stats.adminQuestions.isEmpty && stats.inventorySummary.isEmpty) 
                              ? const Center(child: CircularProgressIndicator())
                              : const Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: LinearProgressIndicator(),
                                ),
                          
                          if (!stats.isLoading && stats.adminQuestions.isEmpty && (stats.inventorySummary.isEmpty || !(_selectedType.isEmpty && _selectedBloom == null && _searchController.text.isEmpty && _selectedTopicId == null)))
                            const Center(child: Text("No questions found.")),
                        ],
                      ),
                    ),
                  ),

                  // Pagination removed per request (1 long page)
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: CozyTheme.shadowSmall,
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 32), // Spread out more
        onTap: (index) {
          setState(() {
            _selectedType = _tabs[index]['type']!;
            final tabTopicId = _tabs[index]['topicId'];
            
            // If this tab represents a subject (has a topicId), set it as current subject
            // Otherwise clear the subject filter
            _currentSubjectId = tabTopicId;
            
            // Reset the section filter when changing tabs
            _selectedTopicId = null;
            _currentPage = 1;
          });
          _refresh();
        },
        tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        labelColor: CozyTheme.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: CozyTheme.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildToolbar(StatsProvider stats) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search questions or topics...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (val) {
              setState(() { _currentPage = 1; });
              _refresh();
            },
          ),
        ),
        // Topic Filter (only show when a subject tab is active)
        if (_currentSubjectId != null) const SizedBox(width: 16),
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
                      child: Text(topic['name'] as String),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<int?>(
            value: _selectedBloom,
            hint: const Text("All Levels"),
            underline: const SizedBox(),
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
        const SizedBox(width: 32),
        ElevatedButton.icon(
          onPressed: () => _showEditDialog(null),
          icon: const Icon(Icons.add),
          label: const Text("New Question"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CozyTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(StatsProvider stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 32, // Increased from 24 to prevent truncation
                horizontalMargin: 12,
                sortColumnIndex: _getSortIndex(),
                sortAscending: _isAscending,
                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                columns: [
                  DataColumn(
                    label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("ID")]),
                    onSort: (col, asc) => _onSort('id', asc),
                  ),
                  const DataColumn(label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Question Text")])),
                  const DataColumn(label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Type")])),
                  DataColumn(
                    label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Section")]),
                    onSort: (col, asc) => _onSort('topic_name', asc),
                  ),
                  DataColumn(
                    label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Bloom")]),
                    onSort: (col, asc) => _onSort('bloom_level', asc),
                  ),
                  DataColumn(
                    label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Attempts")]),
                    onSort: (col, asc) => _onSort('attempts', asc),
                  ),
                  DataColumn(
                    label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Accuracy")]),
                    onSort: (col, asc) => _onSort('success_rate', asc),
                  ),
                  const DataColumn(label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Actions")])),
                ],
                rows: stats.adminQuestions.map((q) {
            final accuracy = q.successRate;
            Color accuracyColor = Colors.grey;
            if (q.attempts > 0) {
              if (accuracy < 40) accuracyColor = Colors.red;
              else if (accuracy < 70) accuracyColor = Colors.orange;
              else accuracyColor = Colors.green;
            }

            return DataRow(cells: [
              DataCell(Center(child: Text(q.id.toString()))),
              DataCell(Container(
                width: 250, // Slightly reduced
                child: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              )),
              DataCell(Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    _getReadableType(q.type),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              )),
              DataCell(Center(child: Text(q.topicName ?? '-'))),
              DataCell(Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                  child: Text("L${q.bloomLevel}", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                ),
              )),
              DataCell(Center(child: Text(q.attempts.toString()))),
              DataCell(Center(
                child: Text(
                  "${accuracy.toStringAsFixed(1)}%",
                  style: TextStyle(color: accuracyColor, fontWeight: FontWeight.bold),
                ),
              )),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20), 
                      onPressed: () => _showEditDialog(q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20), 
                      onPressed: () => _confirmDelete(q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ]);
              }).toList(),
                ),
              ),
            ),
          );
        },
      );
  }

  int? _getSortIndex() {
    switch (_sortBy) {
      case 'id': return 0;
      case 'topic_name': return 3; // Shifted because of Type column
      case 'bloom_level': return 4;
      case 'attempts': return 5;
      case 'success_rate': return 6;
      default: return null;
    }
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

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _isAscending = ascending;
    });
    _refresh();
  }

  Widget _buildPagination(StatsProvider stats) {
    final totalPages = (stats.adminTotalQuestions / 20).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left), 
            onPressed: _currentPage > 1 ? () { setState(() => _currentPage--); _refresh(); } : null,
          ),
          Text("Page $_currentPage of $totalPages"),
          IconButton(
            icon: const Icon(Icons.chevron_right), 
            onPressed: _currentPage < totalPages ? () { setState(() => _currentPage++); _refresh(); } : null,
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
        onSaved: () {
          _refresh();
          Navigator.pop(context);
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

  void _showManageSectionsDialog() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final subjectName = stats.topics.firstWhere(
      (t) => t['id'] == _currentSubjectId, 
      orElse: () => {'name': 'Subject'}
    )['name'];
    
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
                Text(subject['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: CozyTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text("${subject['total']} q", style: TextStyle(color: CozyTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
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
                      title: Text(section['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
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
            color: color.withOpacity(0.1),
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

class QuestionEditorDialog extends StatefulWidget {
  final AdminQuestion? question;
  final VoidCallback onSaved;

  const QuestionEditorDialog({Key? key, this.question, required this.onSaved}) : super(key: key);

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  
  // Relation Analysis fields
  late TextEditingController _statement1Controller;
  late TextEditingController _statement2Controller;
  String? _relationAnswer;
  
  int? _correctIndex;
  int? _selectedTopicId; // This will store the selected section ID
  int? _selectedSubjectId; // New: selected subject ID
  int? _bloomLevel;
  String _questionType = 'single_choice';

  // True/False fields
  late TextEditingController _tfStatementController;
  String? _tfAnswer;

  // Matching fields
  List<MapEntry<TextEditingController, TextEditingController>> _matchingPairs = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question?.text ?? '');
    _explanationController = TextEditingController(text: widget.question?.explanation ?? '');
    _selectedTopicId = widget.question?.topicId;
    _bloomLevel = widget.question?.bloomLevel ?? 1;
    _questionType = widget.question?.type ?? 'single_choice';
    
    // Initialize relation analysis controllers
    _statement1Controller = TextEditingController();
    _statement2Controller = TextEditingController();
    if (_questionType == 'relation_analysis' && widget.question != null) {
      final content = widget.question!.content as Map<String, dynamic>?;
      _statement1Controller.text = content?['statement_1'] ?? '';
      _statement2Controller.text = content?['statement_2'] ?? '';
      _relationAnswer = widget.question!.correctAnswer?.toString() ?? 'A';
    }
    
    // Initialize True/False
    _tfStatementController = TextEditingController();
    if (_questionType == 'true_false' && widget.question != null) {
      final content = widget.question!.content as Map<String, dynamic>?;
      _tfStatementController.text = content?['statement'] ?? '';
      _tfAnswer = widget.question!.correctAnswer?.toString() ?? 'true';
    }

    // Initialize Matching
    if (_questionType == 'matching' && widget.question != null) {
      final content = widget.question!.content as Map<String, dynamic>?;
      final pairsList = content?['pairs'] as List<dynamic>? ?? [];
      _matchingPairs = pairsList.map((p) => MapEntry(
        TextEditingController(text: p['left'] ?? ''),
        TextEditingController(text: p['right'] ?? ''),
      )).toList();
    }
    if (_matchingPairs.isEmpty) {
      _matchingPairs = [MapEntry(TextEditingController(), TextEditingController())];
    }

    // Parse options
    List<String> opts = [];
    if (widget.question != null) {
      // Existing parsing logic...
      if (widget.question!.options is String) {
        try {
          opts = List<String>.from(json.decode(widget.question!.options));
        } catch (e) { opts = []; }
      } else if (widget.question!.options is List) {
        opts = List<String>.from(widget.question!.options);
      }
    }
    
    // Ensure at least 2 controllers for single choice
    if (opts.isEmpty) opts = ['', ''];
    _optionControllers = opts.map((o) => TextEditingController(text: o)).toList();
    
    // Find correct index
    if (_questionType == 'single_choice' && widget.question != null) {
      _correctIndex = opts.indexWhere((o) => o == widget.question!.correctAnswer);
      if (_correctIndex == -1) _correctIndex = 0;
    } else {
      _correctIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatsProvider>(context);
    
    return AlertDialog(
      title: Text(widget.question == null ? "Add Question" : "Edit Question #${widget.question!.id}"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Type Selector
                DropdownButtonFormField<String>(
                  value: _questionType,
                  decoration: const InputDecoration(
                    labelText: "Question Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'single_choice', child: Text('Single Choice')),
                    DropdownMenuItem(value: 'relation_analysis', child: Text('Relation Analysis')),
                    DropdownMenuItem(value: 'true_false', child: Text('True/False')),
                    DropdownMenuItem(value: 'matching', child: Text('Matching (Connect Two)')),
                  ],
                  onChanged: (val) => setState(() => _questionType = val!),
                ),
                const SizedBox(height: 20),

                // Conditional fields based on question type
                if (_questionType == 'single_choice') ...[
                  // Single Choice: Question Text
                  TextFormField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                  ),
                ] else if (_questionType == 'relation_analysis') ...[
                  // Relation Analysis: Statement 1
                  TextFormField(
                    controller: _statement1Controller,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Statement 1",
                      border: OutlineInputBorder(),
                      hintText: "First statement (e.g., 'Insulin decreases blood sugar')",
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  // Relation Analysis: Statement 2
                  TextFormField(
                    controller: _statement2Controller,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Statement 2",
                      border: OutlineInputBorder(),
                      hintText: "Second statement (e.g., 'Insulin is used to treat diabetes')",
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                  ),
                ] else if (_questionType == 'true_false') ...[
                  // True/False: Statement
                  TextFormField(
                    controller: _tfStatementController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Statement",
                      border: OutlineInputBorder(),
                      hintText: "Medical statement to be evaluated",
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tfAnswer,
                    decoration: const InputDecoration(labelText: "Correct Answer", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'true', child: Text('Igaz (True)')),
                      DropdownMenuItem(value: 'false', child: Text('Hamis (False)')),
                    ],
                    onChanged: (val) => setState(() => _tfAnswer = val),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ] else if (_questionType == 'matching') ...[
                  // Matching: Pairs
                  const Text("Pairs (Left matches Right)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...List.generate(_matchingPairs.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _matchingPairs[index].key,
                              decoration: const InputDecoration(hintText: "Left (Term)", border: OutlineInputBorder()),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.link),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _matchingPairs[index].value,
                              decoration: const InputDecoration(hintText: "Right (Match)", border: OutlineInputBorder()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: _matchingPairs.length > 1 
                              ? () => setState(() => _matchingPairs.removeAt(index)) 
                              : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() => _matchingPairs.add(MapEntry(TextEditingController(), TextEditingController()))), 
                    icon: const Icon(Icons.add), 
                    label: const Text("Add Pair")
                  ),
                ],
                const SizedBox(height: 20),
                
                // Subject & Section
                Row(
                  children: [
                    // Subject Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(labelText: "Subject"),
                        items: stats.topics
                          .where((t) => t['parent_id'] == null)
                          .map((t) => DropdownMenuItem(
                            value: t['id'] as int,
                            child: Text(t['name']),
                          )).toList(),
                        onChanged: (val) => setState(() {
                          _selectedSubjectId = val;
                          _selectedTopicId = null; // Reset section when subject changes
                        }),
                        validator: (val) => val == null ? "Select a subject" : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Section Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedTopicId,
                        decoration: const InputDecoration(labelText: "Section"),
                        items: _selectedSubjectId == null
                          ? []
                          : stats.topics
                              .where((t) => t['parent_id'] == _selectedSubjectId)
                              .map((t) => DropdownMenuItem(
                                value: t['id'] as int,
                                child: Text(t['name']),
                              )).toList(),
                        onChanged: (val) => setState(() => _selectedTopicId = val),
                        validator: (val) => val == null ? "Select a section" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Bloom Level (separate row)
                DropdownButtonFormField<int>(
                  value: _bloomLevel,
                  decoration: const InputDecoration(labelText: "Bloom Level"),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("L1: Remember")),
                    DropdownMenuItem(value: 2, child: Text("L2: Understand")),
                    DropdownMenuItem(value: 3, child: Text("L3: Apply")),
                    DropdownMenuItem(value: 4, child: Text("L4: Analyze")),
                  ],
                  onChanged: (val) => setState(() => _bloomLevel = val!),
                ),
                const SizedBox(height: 20),
                
                // Options (Single Choice only)
                if (_questionType == 'single_choice') ...[
                  const Text("Options", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...List.generate(_optionControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: _correctIndex,
                            onChanged: (val) => setState(() => _correctIndex = val),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[index],
                              decoration: InputDecoration(hintText: "Option ${index + 1}"),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: _optionControllers.length > 2 
                              ? () => setState(() => _optionControllers.removeAt(index)) 
                              : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() => _optionControllers.add(TextEditingController())), 
                    icon: const Icon(Icons.add), 
                    label: const Text("Add Option")
                  ),
                ],

                // Relation Analysis Answer
                if (_questionType == 'relation_analysis') ...[
                  const Text("Correct Answer", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _relationAnswer,
                    decoration: const InputDecoration(
                      labelText: "Select correct relationship",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'both_true_related', child: Text('Both true + causal relationship')),
                      DropdownMenuItem(value: 'both_true_unrelated', child: Text('Both true - no relationship')),
                      DropdownMenuItem(value: 'only_first_true', child: Text('Only statement 1 is true')),
                      DropdownMenuItem(value: 'only_second_true', child: Text('Only statement 2 is true')),
                      DropdownMenuItem(value: 'neither_true', child: Text('Neither statement is true')),
                    ],
                    onChanged: (val) => setState(() => _relationAnswer = val),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ],
                const SizedBox(height: 20),

                // Explanation
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Explanation (Post-quiz feedback)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: CozyTheme.primary, foregroundColor: Colors.white),
          child: const Text("Save"),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    Map<String, dynamic> content;
    String correctAnswer;

    // Build content and correct_answer based on question type
    if (_questionType == 'single_choice') {
      final options = _optionControllers.map((c) => c.text).toList();
      if (_correctIndex == null || _correctIndex! >= options.length) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a correct answer")));
         return;
      }

      content = {
        'question_text': _textController.text,
        'options': options,
      };
      correctAnswer = options[_correctIndex!];
    } else if (_questionType == 'relation_analysis') {
      if (_relationAnswer == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a correct answer")));
         return;
      }

      content = {
        'statement_1': _statement1Controller.text,
        'statement_2': _statement2Controller.text,
      };
      correctAnswer = _relationAnswer!;
    } else if (_questionType == 'true_false') {
      if (_tfAnswer == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a correct answer")));
         return;
      }

      content = {
        'statement': _tfStatementController.text,
      };
      correctAnswer = _tfAnswer!;
    } else if (_questionType == 'matching') {
      // Validate pairs
      final validPairs = _matchingPairs.where((p) => p.key.text.isNotEmpty && p.value.text.isNotEmpty).toList();
      if (validPairs.length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least 2 valid pairs")));
         return;
      }

      final pairsList = validPairs.map((p) => {
        'left': p.key.text,
        'right': p.value.text,
      }).toList();

      content = {
        'pairs': pairsList,
      };
      
      // correct_answer is a map of left to right
      final Map<String, String> answerMap = {};
      for (var p in validPairs) {
        answerMap[p.key.text] = p.value.text;
      }
      correctAnswer = json.encode(answerMap);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown question type")));
      return;
    }

    String text;
    if (_questionType == 'single_choice') {
      text = _textController.text;
    } else if (_questionType == 'relation_analysis') {
      text = "${_statement1Controller.text} | ${_statement2Controller.text}";
    } else if (_questionType == 'true_false') {
      text = _tfStatementController.text;
    } else if (_questionType == 'matching') {
      text = "Párosítsd a kifejezéseket!";
    } else {
      text = _textController.text;
    }

    final data = {
      'question_type': _questionType,
      'content': content,
      'correct_answer': correctAnswer,
      'explanation': _explanationController.text,
      'topic_id': _selectedTopicId,
      'bloom_level': _bloomLevel,
      'difficulty': _bloomLevel,
      'text': text,
    };

    final stats = Provider.of<StatsProvider>(context, listen: false);
    bool success;
    if (widget.question == null) {
      success = await stats.createQuestion(data);
    } else {
      success = await stats.updateQuestion(widget.question!.id, data);
    }

    if (success) {
      widget.onSaved();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save. Check server logs.")));
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
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSection() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Section name cannot be empty")),
      );
      return;
    }

    setState(() => _isCreating = true);
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final success = await stats.createTopic(_nameController.text.trim(), widget.subjectId);
    setState(() => _isCreating = false);

    if (success) {
      _nameController.clear();
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

    if (confirm != true) return;

    final stats = Provider.of<StatsProvider>(context, listen: false);
    final error = await stats.deleteTopic(topicId);

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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "New section name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _createSection(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createSection,
                  icon: _isCreating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                  label: const Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CozyTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
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
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(section['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteSection(section['id'], section['name']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
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
