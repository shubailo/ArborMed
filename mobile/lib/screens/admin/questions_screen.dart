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
                          // Always show table if we have data to prevent flashing
                          if (stats.adminQuestions.isNotEmpty)
                            Positioned.fill(child: _buildTable(stats)),
                          
                          // Loading indicator overlay (Non-blocking)
                          if (stats.isLoading)
                            stats.adminQuestions.isEmpty 
                              ? const Center(child: CircularProgressIndicator())
                              : const Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: LinearProgressIndicator(),
                                ),
                          
                          if (!stats.isLoading && stats.adminQuestions.isEmpty)
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
                columnSpacing: 48, // Significantly more spread
                horizontalMargin: 24,
                sortColumnIndex: _getSortIndex(),
                sortAscending: _isAscending,
                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                columns: [
                  DataColumn(label: const Text("ID"), onSort: (col, asc) => _onSort('id', asc)),
                  const DataColumn(label: Text("Question Text")),
                  DataColumn(label: const Text("Topic"), onSort: (col, asc) => _onSort('topic_name', asc)),
                  DataColumn(label: const Text("Bloom"), onSort: (col, asc) => _onSort('bloom_level', asc)),
                  DataColumn(label: const Text("Attempts"), onSort: (col, asc) => _onSort('attempts', asc)),
                  DataColumn(label: const Text("Accuracy"), onSort: (col, asc) => _onSort('success_rate', asc)),
                  const DataColumn(label: Text("Actions")),
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
              DataCell(Text(q.id.toString())),
              DataCell(Container(
                width: 300,
                child: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              )),
              DataCell(Text(q.topicName ?? '-')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                child: Text("L${q.bloomLevel}", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
              )),
              DataCell(Text(q.attempts.toString())),
              DataCell(Text(
                "${accuracy.toStringAsFixed(1)}%",
                style: TextStyle(color: accuracyColor, fontWeight: FontWeight.bold),
              )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min, // Constrain row height/width
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue), 
                        onPressed: () => _showEditDialog(q),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        onPressed: () => _confirmDelete(q),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )),
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
      case 'topic_name': return 2;
      case 'bloom_level': return 3;
      case 'attempts': return 4;
      case 'success_rate': return 5;
      default: return null;
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
  int? _correctIndex;
  int? _selectedTopicId;
  int _bloomLevel = 1;
  late String _type;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question?.text ?? '');
    _explanationController = TextEditingController(text: widget.question?.explanation ?? '');
    _selectedTopicId = widget.question?.topicId;
    _bloomLevel = widget.question?.bloomLevel ?? 1;
    _type = widget.question?.type ?? 'single_choice';

    // Parse options
    List<String> opts = [];
    if (widget.question != null) {
      if (widget.question!.options is String) {
        try {
          opts = List<String>.from(json.decode(widget.question!.options));
        } catch (e) { opts = []; }
      } else if (widget.question!.options is List) {
        opts = List<String>.from(widget.question!.options);
      }
    }
    
    // Ensure at least 2 controllers
    if (opts.isEmpty) opts = ['', ''];
    _optionControllers = opts.map((o) => TextEditingController(text: o)).toList();
    
    // Find correct index
    if (widget.question != null) {
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
                // Text
                TextFormField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 20),
                
                // Topic & Bloom
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedTopicId,
                        decoration: const InputDecoration(labelText: "Topic"),
                        items: stats.topics.map((t) => DropdownMenuItem(
                          value: t['id'] as int,
                          child: Text(t['name']),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedTopicId = val),
                        validator: (val) => val == null ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                     Expanded(
                      child: DropdownButtonFormField<int>(
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
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Question Type
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: "Question Type"),
                  items: const [
                    DropdownMenuItem(value: 'single_choice', child: Text("General (Single Choice)")),
                    DropdownMenuItem(value: 'ecg', child: Text("ECG")),
                    DropdownMenuItem(value: 'case_study', child: Text("Case Study")),
                  ],
                  onChanged: (val) => setState(() => _type = val!),
                ),
                const SizedBox(height: 30),

                // Options
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
    
    final options = _optionControllers.map((c) => c.text).toList();
    if (_correctIndex == null || _correctIndex! >= options.length) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a correct answer")));
       return;
    }

    final data = {
      'text': _textController.text,
      'topic_id': _selectedTopicId,
      'bloom_level': _bloomLevel,
      'difficulty': _bloomLevel,
      'options': options,
      'correct_answer': options[_correctIndex!],
      'explanation': _explanationController.text,
      'type': _type,
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
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSection(section['id'], section['name']),
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
