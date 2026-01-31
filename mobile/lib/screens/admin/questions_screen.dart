import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_guard.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import 'dart:convert';
import '../../widgets/admin/dual_language_field.dart';
import '../../services/translation_service.dart';
import 'package:http/http.dart' as http; // For TranslationService instantiation if not in provider

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
        topics: Provider.of<StatsProvider>(context, listen: false).topics,
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
  final List<dynamic> topics; // Accepted topics list
  final VoidCallback onSaved;

  const QuestionEditorDialog({Key? key, this.question, required this.topics, required this.onSaved}) : super(key: key);

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final TranslationService _translationService = TranslationService(baseUrl: 'http://localhost:3000'); // Adjust URL as needed

  // English Controllers
  late TextEditingController _textControllerEn;
  late TextEditingController _explanationControllerEn;
  late List<TextEditingController> _optionControllersEn;
  
  // Hungarian Controllers
  late TextEditingController _textControllerHu;
  late TextEditingController _explanationControllerHu;
  late List<TextEditingController> _optionControllersHu;
  
  // Loading States
  bool _isTranslating = false;

  // Relation Analysis fields
  late TextEditingController _statement1Controller;
  late TextEditingController _statement2Controller;
  String? _relationAnswer;
  
  int? _correctIndex;
  int? _selectedTopicId; 
  int? _selectedSubjectId; 
  int? _bloomLevel;
  String _questionType = 'single_choice';

  // True/False fields
  late TextEditingController _tfStatementController;
  String? _tfAnswer;

  // Matching fields (Simplified for now - shared content or language specific?)
  // For full implementation, matching pairs should arguably be translated too.
  // For MVP of full impl, let's keep matching pairs single/shared or just EN for now to reduce complexity, 
  // OR duplicate them. Let's start with single choice full support.
  List<MapEntry<TextEditingController, TextEditingController>> _matchingPairs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize English Controllers (load from en fields)
    _textControllerEn = TextEditingController(text: widget.question?.text ?? ''); // Maps to text/question_text_en
    _explanationControllerEn = TextEditingController(text: widget.question?.explanation ?? '');

    // Initialize Hungarian Controllers 
    // Note: AdminQuestion model needs update to hold hu fields locally if we want to edit them
    // For now, let's assume the API returns them or we fetch them. 
    // Since AdminQuestion might not have them yet (we just added cols), 
    // we'll default to empty or copy EN if new.
    // Ideally AdminQuestion struct needs 'question_text_hu' etc.
    // Let's assume widget.question has a map 'raw' or we can pass data.
    // For this step, I'll initialize empty.
    _textControllerHu = TextEditingController(text: widget.question?.questionTextHu ?? ''); 
    _explanationControllerHu = TextEditingController(text: widget.question?.explanationHu ?? '');

    _selectedTopicId = widget.question?.topicId;
    
    // Initialize Subject ID based on Topic ID
    if (_selectedTopicId != null) {
      final topic = widget.topics.firstWhere(
        (t) => t['id'] == _selectedTopicId, 
        orElse: () => null
      );
      if (topic != null) {
        _selectedSubjectId = topic['parent_id'];
      }
    }
    
    _bloomLevel = widget.question?.bloomLevel ?? 1;
    _questionType = widget.question?.type ?? 'single_choice';
    
    // ... (Init legacy fields for other types if needed) ...
    _statement1Controller = TextEditingController(); // ... existing init
    _statement2Controller = TextEditingController();
    // ... [Legacy implementations kept for safety but focused on Single Choice]
    
    // Parse Options
    _initOptions();
  }

  void _initOptions() {
    // English Options
    List<String> optsEn = [];
    if (widget.question != null) {
      dynamic rawOptions = widget.question!.options;
      
      // Handle String (Legacy JSON)
      if (rawOptions is String) {
        try {
          // It might be a Map encoded as string or a List encoded as string
          final decoded = json.decode(rawOptions);
          if (decoded is List) {
            optsEn = List<String>.from(decoded);
          } else if (decoded is Map) {
             // If it's {"en": [...], "hu": [...]}
             if (decoded.containsKey('en')) {
               optsEn = List<String>.from(decoded['en']);
             }
          }
        } catch (e) {
          optsEn = [];
        }
      } 
      // Handle List (Legacy direct)
      else if (rawOptions is List) {
        optsEn = List<String>.from(rawOptions);
      }
      // Handle Map (New Structure)
      else if (rawOptions is Map) {
         if (rawOptions.containsKey('en')) {
           optsEn = List<String>.from(rawOptions['en']);
         }
      }
    }
    if (optsEn.isEmpty) optsEn = ['', '', '', '']; // Default 4 options
    _optionControllersEn = optsEn.map((o) => TextEditingController(text: o)).toList();

    // Hungarian Options
    // Since we just migrated, options might be {"en": [], "hu": []} or just []
    // We need to handle parsing carefully.
    List<String> optsHu = [];
    // Logic to parse HU options if available
    if (widget.question?.optionsHu != null) {
        optsHu = widget.question!.optionsHu!;
    } else {
        optsHu = List.filled(optsEn.length, '');
    }
    _optionControllersHu = optsHu.map((o) => TextEditingController(text: o)).toList();

    // Ensure lengths match
    while (_optionControllersHu.length < _optionControllersEn.length) {
      _optionControllersHu.add(TextEditingController());
    }

    // Set Correct Answer Index
    if (_questionType == 'single_choice' && widget.question != null) {
      _correctIndex = optsEn.indexWhere((o) => o == widget.question!.correctAnswer);
      if (_correctIndex == -1) _correctIndex = 0;
    } else {
      _correctIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? "Add Question" : "Edit Question #${widget.question!.id}"),
      content: SizedBox(
        width: 800, // Widened for tabular view
        height: 600,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Shared Metadata (Type, Topic, Bloom)
              _buildMetadataSection(),
              const SizedBox(height: 16),
              const Divider(),
              
              // 2. Language Tabs
              TabBar(
                controller: _tabController,
                labelColor: CozyTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: CozyTheme.primary,
                tabs: const [
                  Tab(text: "🇬🇧 English", icon: Icon(Icons.language)),
                  Tab(text: "🇭🇺 Hungarian", icon: Icon(Icons.translate)),
                ],
              ),
              const SizedBox(height: 16),
              
              // 3. Editor Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                         // Translate Button for EN (Usually from HU)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 8),
                           child: Align(
                             alignment: Alignment.centerRight,
                             child: ElevatedButton.icon(
                               onPressed: _isTranslating ? null : () => _translateAll('hu', 'en'),
                               icon: _isTranslating ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.translate),
                               label: const Text("Translate from HU (All)"),
                             ),
                           ),
                         ),
                        Expanded(child: _buildLanguagePanel('en')),
                      ],
                    ),
                    Column(
                      children: [
                         // Translate Button for HU (from EN)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 8),
                           child: Align(
                             alignment: Alignment.centerRight,
                             child: ElevatedButton.icon(
                               onPressed: _isTranslating ? null : () => _translateAll('en', 'hu'),
                               icon: _isTranslating ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.translate),
                               label: const Text("Auto-Translate to HU (All)"),
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                             ),
                           ),
                         ),
                        Expanded(child: _buildLanguagePanel('hu')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: CozyTheme.primary, foregroundColor: Colors.white),
          child: const Text("Save Question"),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    // 1. Filter Subjects (Parent Topics)
    final subjects = widget.topics.where((t) => t['parent_id'] == null).toList();
    
    // 2. Filter Sections based on selected user Subject
    List<dynamic> sections = [];
    if (_selectedSubjectId != null) {
      sections = widget.topics.where((t) => t['parent_id'] == _selectedSubjectId).toList();
    }

    return Column(
      children: [
        // Row 1: Type & Bloom
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _questionType,
                decoration: const InputDecoration(
                  labelText: "Question Type", 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                   DropdownMenuItem(value: 'single_choice', child: Text('Single Choice')),
                   DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                   DropdownMenuItem(value: 'true_false', child: Text('True/False')),
                   DropdownMenuItem(value: 'relation_analysis', child: Text('Relation Analysis')),
                   DropdownMenuItem(value: 'matching', child: Text('Matching')),
                ],
                onChanged: (val) {
                  setState(() {
                    _questionType = val!;
                    _onTypeChanged();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: _bloomLevel,
                decoration: const InputDecoration(
                  labelText: "Bloom Criteria", 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [1, 2, 3, 4].map((l) => DropdownMenuItem(value: l, child: Text("Level $l"))).toList(),
                onChanged: (val) => setState(() => _bloomLevel = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Subject & Section
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: "Subject", 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: subjects.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem(value: s['id'] as int, child: Text(s['name']));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    _selectedTopicId = null; // Reset section when subject changes
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedTopicId,
                decoration: const InputDecoration(
                  labelText: "Section", 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: sections.isEmpty 
                    ? [] 
                    : sections.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem(value: s['id'] as int, child: Text(s['name']));
                      }).toList(),
                onChanged: sections.isEmpty ? null : (val) => setState(() => _selectedTopicId = val),
                 // Disable if no sections
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onTypeChanged() {
    if (_questionType == 'relation_analysis') {
      // Pre-fill standard Relation Analysis options
      final raOptions = [
        "A: I is correct, II is correct, Link is correct",
        "B: I is correct, II is correct, Link is incorrect",
        "C: I is correct, II is incorrect",
        "D: I is incorrect, II is correct",
        "E: Both incorrect"
      ];
      // Resize to 5
      while(_optionControllersEn.length < 5) _optionControllersEn.add(TextEditingController());
      while(_optionControllersHu.length < 5) _optionControllersHu.add(TextEditingController());
      
      for(int i=0; i<5; i++) {
        _optionControllersEn[i].text = raOptions[i];
        _optionControllersHu[i].text = raOptions[i]; // Can be manually translated later
      }
    } else if (_questionType == 'true_false') {
       final tfOptions = ["True", "False"];
       // Resize to 2
       // Ensure at least 2 controllers
       while(_optionControllersEn.length < 2) _optionControllersEn.add(TextEditingController());
       while(_optionControllersHu.length < 2) _optionControllersHu.add(TextEditingController());
       
       _optionControllersEn[0].text = "True"; _optionControllersEn[1].text = "False";
       _optionControllersHu[0].text = "Igaz"; _optionControllersHu[1].text = "Hamis";
    }
  }

  Future<void> _translateAll(String source, String target) async {
    setState(() => _isTranslating = true);
    
    try {
      final srcText = source == 'en' ? _textControllerEn.text : _textControllerHu.text;
      final srcExp = source == 'en' ? _explanationControllerEn.text : _explanationControllerHu.text;
      final srcOpts = source == 'en' 
          ? _optionControllersEn.map((c) => c.text).toList() 
          : _optionControllersHu.map((c) => c.text).toList();
          
      final result = await _translationService.translateQuestion(
        questionData: {
          'questionText': srcText,
          'explanation': srcExp,
          'options': srcOpts,
        },
        from: source,
        to: target,
      );
      
      if (result != null) {
        if (target == 'hu') {
          if (result['questionText'] != null) _textControllerHu.text = result['questionText'];
          if (result['explanation'] != null) _explanationControllerHu.text = result['explanation'];
          if (result['options'] != null) {
             final opts = result['options'] as List;
             for(int i=0; i<opts.length && i<_optionControllersHu.length; i++) {
               _optionControllersHu[i].text = opts[i];
             }
          }
        } else {
           // Target EN (Reverse)
          if (result['questionText'] != null) _textControllerEn.text = result['questionText'];
          if (result['explanation'] != null) _explanationControllerEn.text = result['explanation'];
          if (result['options'] != null) {
             final opts = result['options'] as List;
             for(int i=0; i<opts.length && i<_optionControllersEn.length; i++) {
               _optionControllersEn[i].text = opts[i];
             }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation failed: $e")));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Widget _buildLanguagePanel(String lang) {
    final isEn = lang == 'en';
    final txtCtrl = isEn ? _textControllerEn : _textControllerHu;
    final expCtrl = isEn ? _explanationControllerEn : _explanationControllerHu;
    final optCtrls = isEn ? _optionControllersEn : _optionControllersHu;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Question Text
          DualLanguageField(
            controllerEn: _textControllerEn,
            controllerHu: _textControllerHu,
            label: "Question Text",
            currentLanguage: lang,
            isMultiLine: true,
            isTranslating: _isTranslating,
            onTranslate: () => _translateField(
              from: isEn ? 'hu' : 'en', 
              to: lang, 
              sourceCtrl: isEn ? _textControllerHu : _textControllerEn,
              targetCtrl: txtCtrl
            ),
          ),
          const SizedBox(height: 16),
          
          // Options
          if (_questionType == 'single_choice')
             ...List.generate(optCtrls.length, (index) {
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
                        child: DualLanguageField(
                          controllerEn: _optionControllersEn[index],
                          controllerHu: _optionControllersHu[index],
                          label: "Option ${String.fromCharCode(65 + index)}",
                          currentLanguage: lang,
                          onTranslate: () => _translateField(
                            from: isEn ? 'hu' : 'en',
                            to: lang,
                            sourceCtrl: isEn ? _optionControllersHu[index] : _optionControllersEn[index],
                            targetCtrl: optCtrls[index],
                          ),
                        ),
                      ),
                    ],
                 ),
               );
             }),

          const SizedBox(height: 16),
          // Explanation
          DualLanguageField(
            controllerEn: _explanationControllerEn,
            controllerHu: _explanationControllerHu,
            label: "Explanation",
            currentLanguage: lang,
            isMultiLine: true,
            isTranslating: _isTranslating,
            onTranslate: () => _translateField(
              from: isEn ? 'hu' : 'en', 
              to: lang, 
              sourceCtrl: isEn ? _explanationControllerHu : _explanationControllerEn, 
              targetCtrl: expCtrl
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translateField({
    required String from, 
    required String to, 
    required TextEditingController sourceCtrl, 
    required TextEditingController targetCtrl
  }) async {
    if (sourceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Source field is empty!")));
      return;
    }
    
    setState(() => _isTranslating = true);
    try {
      final translated = await _translationService.translateText(sourceCtrl.text, from, to);
      if (translated != null) {
        setState(() => targetCtrl.text = translated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Translation failed")));
      }
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Prepare Data
    // Note: This needs to conform to what the backend expects for multi-lang saving
    // Since we updated 010_multi_language_support.sql, we have separate cols.
    // The backend createQuestion/updateQuestion needs to handle this payload.
    
    final payload = {
      'question_text_en': _textControllerEn.text,
      'question_text_hu': _textControllerHu.text,
      'options_en': _optionControllersEn.map((c) => c.text).toList(),
      'options_hu': _optionControllersHu.map((c) => c.text).toList(),
      'explanation_en': _explanationControllerEn.text,
      'explanation_hu': _explanationControllerHu.text,
      'correct_answer_en': _optionControllersEn[_correctIndex ?? 0].text,
      
      // Meta
      'type': _questionType,
      'topic_id': _selectedTopicId,
      'bloom_level': _bloomLevel,
    };

    final stats = Provider.of<StatsProvider>(context, listen: false);
    // Call new method or updated createQuestion
    // await stats.saveQuestionMultiLang(widget.question?.id, payload);
    
    // For now, I'll close dialog
    widget.onSaved();
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
