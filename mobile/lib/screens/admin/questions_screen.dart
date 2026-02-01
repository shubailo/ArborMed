import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/stats_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import 'dart:convert';
import '../../widgets/admin/dual_language_field.dart';
import '../../widgets/admin/dynamic_option_list.dart';
import '../../services/translation_service.dart';
// For TranslationService instantiation if not in provider
import 'ecg_editor_dialog.dart'; // Import the new dialog

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

    return DefaultTabController(
      length: _tabs.length,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                      ? _buildECGTable(stats) // New ECG Table
                                      : (stats.adminQuestions.isNotEmpty 
                                          ? _buildTable(stats)
                                          : Center(child: Text("No questions found.", style: TextStyle(color: Colors.grey[400])))),
                                ),
                          ),
                        ),
                        
                        // Loading indicator overlay (Non-blocking)
                        if (stats.isLoading)
                          (stats.adminQuestions.isEmpty && stats.inventorySummary.isEmpty) 
                            ? const Center(child: CircularProgressIndicator())
                            : const Positioned(
                                top: 0, left: 0, right: 0,
                                child: LinearProgressIndicator(minHeight: 3),
                              ),
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
        ElevatedButton.icon(
          onPressed: () => _selectedType == 'ecg' ? _showECGEditDialog(null) : _showEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(_selectedType == 'ecg' ? "New ECG Case" : "New Question"),
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
        const int textFlex = 4;
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

                  return Container(
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
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
                        _buildFlexCell(Text(q.topicNameEn ?? q.topicNameHu ?? '-', style: const TextStyle(fontSize: 12)), sectionFlex, center: true),
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

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _isAscending = ascending;
    });
    _refresh();
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
  // late List<TextEditingController> _optionControllersEn; // Removed for Dynamic List

  // Hungarian Controllers
  late TextEditingController _textControllerHu;
  late TextEditingController _explanationControllerHu;
  // late List<TextEditingController> _optionControllersHu; // Removed

  // Option Lists (Dynamic)
  List<String> _currentOptionsEn = ['', '', '', ''];
  List<String> _currentOptionsHu = ['', '', '', ''];

  // Image Upload
  XFile? _selectedImage;
  String? _existingImageUrl;
  
  // Loading States
  bool _isTranslating = false;

  // Relation Analysis fields
  late TextEditingController _s1EnController;
  late TextEditingController _s1HuController;
  late TextEditingController _s2EnController;
  late TextEditingController _s2HuController;
  late TextEditingController _linkEnController;
  late TextEditingController _linkHuController;
  
  // Matching fields (1-to-1)
  final List<MatchingPairControllerGroup> _matchingGroups = [];

  // Multiple Choice (Multi-select)
  final List<int> _multipleCorrectIndices = [];

  // Metadata Fields
  int? _selectedTopicId;
  int? _selectedSubjectId;
  int _bloomLevel = 1;
  String _questionType = 'single_choice';
  int? _correctIndex;
  late TextEditingController _tfStatementController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });

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
      for (var t in widget.topics) {
        if (t['id'] == _selectedTopicId) {
          _selectedSubjectId = t['parent_id'];
          break;
        }
      }
    }
    
    _bloomLevel = widget.question?.bloomLevel ?? 1;
    _questionType = widget.question?.type ?? 'single_choice';
    
    // ... (Init legacy fields for other types if needed) ...
    // Relation Analysis Init
    _s1EnController = TextEditingController();
    _s1HuController = TextEditingController();
    _s2EnController = TextEditingController();
    _s2HuController = TextEditingController();
    _linkEnController = TextEditingController(text: 'because');
    _linkHuController = TextEditingController(text: 'mert');

    // True/False Init
    _tfStatementController = TextEditingController();

    // Load data if editing
    _loadTypeSpecificData();
    
    // Parse Options & Image
    _initOptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textControllerEn.dispose();
    _explanationControllerEn.dispose();
    _textControllerHu.dispose();
    _explanationControllerHu.dispose();
    for (var group in _matchingGroups) {
      group.dispose();
    }
    _s1EnController.dispose();
    _s1HuController.dispose();
    _s2EnController.dispose();
    _s2HuController.dispose();
    _linkEnController.dispose();
    _linkHuController.dispose();
    _tfStatementController.dispose();
    super.dispose();
  }

  void _initOptions() {
    // 1. Image
    if (widget.question?.content != null && widget.question!.content is Map) {
      _existingImageUrl = widget.question!.content['image_url'];
    }

    // 2. English Options
    List<String> optsEn = [];
    if (widget.question != null) {
      dynamic rawOptions = widget.question!.options;
      if (rawOptions is String) {
        try {
          final decoded = json.decode(rawOptions);
          if (decoded is List) {
            optsEn = (decoded).map((e) => e?.toString() ?? '').toList();
          } else if (decoded is Map && decoded.containsKey('en')) {
            optsEn = (decoded['en'] as List).map((e) => e?.toString() ?? '').toList();
          }
        } catch (_) {}
      } else if (rawOptions is List) {
        optsEn = (rawOptions).map((e) => e?.toString() ?? '').toList();
      } else if (rawOptions is Map && rawOptions.containsKey('en')) {
         optsEn = (rawOptions['en'] as List).map((e) => e?.toString() ?? '').toList();
      }
    }
    if (optsEn.isEmpty) optsEn = ['', '', '', ''];
    _currentOptionsEn = optsEn;

    // 3. Hungarian Options
    List<String> optsHu = [];
    if (widget.question?.optionsHu != null) {
        optsHu = widget.question!.optionsHu!;
    } else {
        optsHu = List.filled(_currentOptionsEn.length, '');
    }
    
    // Sync Lengths
    while (optsHu.length < _currentOptionsEn.length) {
      optsHu.add('');
    }
    _currentOptionsHu = optsHu;

    // 4. Correct Index
    if (_questionType == 'single_choice' && widget.question != null) {
      _correctIndex = _currentOptionsEn.indexWhere((o) => o == widget.question!.correctAnswer);
      if (_correctIndex == -1) _correctIndex = 0;
    } else {
      _correctIndex = 0;
    }
  }

  void _loadTypeSpecificData() {
    if (widget.question == null) return;
    final content = widget.question!.content;
    if (content == null || content is! Map) return;

    if (_questionType == 'relation_analysis') {
      _s1EnController.text = content['statement1']?['en'] ?? '';
      _s1HuController.text = content['statement1']?['hu'] ?? '';
      _s2EnController.text = content['statement2']?['en'] ?? '';
      _s2HuController.text = content['statement2']?['hu'] ?? '';
      _linkEnController.text = content['link_word']?['en'] ?? 'because';
      _linkHuController.text = content['link_word']?['hu'] ?? 'mert';
      
      final corr = widget.question!.correctAnswer;
      if (corr is String) {
        // Find alphabetical index (A=0, B=1, ...)
        final idx = corr.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 && idx < 5) _correctIndex = idx;
      }
    } else if (_questionType == 'true_false') {
      _textControllerEn.text = content['statement']?['en'] ?? '';
      _textControllerHu.text = content['statement']?['hu'] ?? '';
      final corr = widget.question!.correctAnswer.toString().toLowerCase();
      _correctIndex = (corr == 'true') ? 0 : 1;
    } else if (_questionType == 'matching') {
      final List<dynamic>? pairs = content['pairs'];
      if (pairs != null) {
        for (var p in pairs) {
          _matchingGroups.add(MatchingPairControllerGroup(
            leftE: p['left']?['en'] ?? '',
            leftH: p['left']?['hu'] ?? '',
            rightE: p['right']?['en'] ?? '',
            rightH: p['right']?['hu'] ?? '',
          ));
        }
      }
    } else if (_questionType == 'multiple_choice') {
       final corr = widget.question!.correctAnswer;
       if (corr is List) {
         for (var val in corr) {
           final idx = _currentOptionsEn.indexOf(val.toString());
           if (idx != -1) _multipleCorrectIndices.add(idx);
         }
       }
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
              // 2. Compact Header: Tabs + Global Translate Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          labelColor: CozyTheme.primary,
                          unselectedLabelColor: Colors.grey.shade600,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("🇬🇧"), 
                                  SizedBox(width: 8), 
                                  Text("English"),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("🇭🇺"), 
                                  SizedBox(width: 8), 
                                  Text("Hungarian"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Clean Translate Action
                      Container(
                        height: 38,
                        margin: const EdgeInsets.only(right: 4),
                        child: TextButton.icon(
                          onPressed: _isTranslating ? null : () {
                            if (_tabController.index == 0) {
                              _translateAll('hu', 'en');
                            } else {
                              _translateAll('en', 'hu');
                            }
                          },
                          icon: _isTranslating 
                              ? const SizedBox(width:12, height:12, child: CircularProgressIndicator(strokeWidth:2)) 
                              : Icon(Icons.auto_awesome, size: 16, color: _tabController.index == 1 ? Colors.orange : CozyTheme.primary),
                          label: Text(
                             _tabController.index == 0 ? "From HU" : "Auto Fill",
                             style: TextStyle(
                               fontSize: 12, 
                               fontWeight: FontWeight.bold,
                               color: _tabController.index == 1 ? Colors.orange.shade800 : CozyTheme.primary
                             ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: _tabController.index == 1 ? Colors.orange.withOpacity(0.1) : CozyTheme.primary.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Space instead of Divider
              
              // 3. Editor Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLanguagePanel('en'),
                    _buildLanguagePanel('hu'),
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
                  return DropdownMenuItem(
                    value: s['id'] as int, 
                    child: Text(s['name']?.toString() ?? s['name_en']?.toString() ?? 'Unnamed Subject'),
                  );
                }).toList(),
                validator: (val) => val == null ? "Please select a Subject" : null,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: "Section", 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                   if (_selectedSubjectId != null && val == null) {
                     return "Please select a Section";
                   }
                   return null;
                },
                items: sections.isEmpty 
                    ? [] 
                    : sections.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem(
                          value: s['id'] as int, 
                          child: Text(s['name']?.toString() ?? s['name_en']?.toString() ?? 'Unnamed Topic'),
                        );
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
    // Instant Morphing: Initialize state for the new type
    if (_questionType == 'relation_analysis') {
      _currentOptionsEn = ["A", "B", "C", "D", "E"];
      _currentOptionsHu = ["A", "B", "C", "D", "E"];
      _correctIndex = 0;
      // Reset RA specific controllers if they are empty
      if (_s1EnController.text.isEmpty) {
        _linkEnController.text = 'because';
        _linkHuController.text = 'mert';
      }
    } else if (_questionType == 'true_false') {
      _currentOptionsEn = ["True", "False"];
      _currentOptionsHu = ["Igaz", "Hamis"];
      _correctIndex = 0;
    } else if (_questionType == 'matching') {
      if (_matchingGroups.isEmpty) {
        _matchingGroups.add(MatchingPairControllerGroup());
        _matchingGroups.add(MatchingPairControllerGroup());
      }
    } else if (_questionType == 'multiple_choice') {
      // Keep existing options if any, but ensure it's multi-select
      if (_currentOptionsEn.length < 2) {
        _currentOptionsEn = ["", "", "", ""];
        _currentOptionsHu = ["", "", "", ""];
      }
    } else {
      // single_choice
      if (_currentOptionsEn.length < 2) {
        _currentOptionsEn = ["", "", "", ""];
        _currentOptionsHu = ["", "", "", ""];
      }
    }
  }

  Future<void> _translateAll(String source, String target) async {
    setState(() => _isTranslating = true);
    
    try {
      final Map<String, dynamic> srcData = {
        'explanation': source == 'en' ? _explanationControllerEn.text : _explanationControllerHu.text,
      };

      if (_questionType == 'relation_analysis') {
        srcData['statement1'] = source == 'en' ? _s1EnController.text : _s1HuController.text;
        srcData['statement2'] = source == 'en' ? _s2EnController.text : _s2HuController.text;
        srcData['link_word'] = source == 'en' ? _linkEnController.text : _linkHuController.text;
      } else if (_questionType == 'matching') {
        srcData['lefts'] = _matchingGroups.map((MatchingPairControllerGroup g) => source == 'en' ? g.leftEn.text : g.leftHu.text).toList();
        srcData['rights'] = _matchingGroups.map((MatchingPairControllerGroup g) => source == 'en' ? g.rightEn.text : g.rightHu.text).toList();
      } else {
        srcData['questionText'] = source == 'en' ? _textControllerEn.text : _textControllerHu.text;
        srcData['options'] = source == 'en' ? _currentOptionsEn : _currentOptionsHu;
      }
          
      final result = await _translationService.translateQuestion(
        questionData: srcData,
        from: source,
        to: target,
      );
      
      if (result != null) {
        setState(() {
          if (target == 'hu') {
            if (result['explanation'] != null) _explanationControllerHu.text = result['explanation'];
            
            if (_questionType == 'relation_analysis') {
              if (result['statement1'] != null) _s1HuController.text = result['statement1'];
              if (result['statement2'] != null) _s2HuController.text = result['statement2'];
              if (result['link_word'] != null) _linkHuController.text = result['link_word'];
            } else if (_questionType == 'matching') {
              if (result['lefts'] != null) {
                final list = result['lefts'] as List;
                for (int i=0; i<list.length && i<_matchingGroups.length; i++) {
                  _matchingGroups[i].leftHu.text = list[i].toString();
                }
              }
              if (result['rights'] != null) {
                final list = result['rights'] as List;
                for (int i=0; i<list.length && i<_matchingGroups.length; i++) {
                  _matchingGroups[i].rightHu.text = list[i].toString();
                }
              }
            } else {
              if (result['questionText'] != null) _textControllerHu.text = result['questionText'];
              if (result['options'] != null) {
                _currentOptionsHu = (result['options'] as List).map((e) => e.toString()).toList();
              }
            }
          } else {
            // Target EN
            if (result['explanation'] != null) _explanationControllerEn.text = result['explanation'];
            
            if (_questionType == 'relation_analysis') {
              if (result['statement1'] != null) _s1EnController.text = result['statement1'];
              if (result['statement2'] != null) _s2EnController.text = result['statement2'];
              if (result['link_word'] != null) _linkEnController.text = result['link_word'];
            } else if (_questionType == 'matching') {
              if (result['lefts'] != null) {
                final list = result['lefts'] as List;
                for (int i=0; i<list.length && i<_matchingGroups.length; i++) {
                  _matchingGroups[i].leftEn.text = list[i].toString();
                }
              }
              if (result['rights'] != null) {
                final list = result['rights'] as List;
                for (int i=0; i<list.length && i<_matchingGroups.length; i++) {
                  _matchingGroups[i].rightEn.text = list[i].toString();
                }
              }
            } else {
              if (result['questionText'] != null) _textControllerEn.text = result['questionText'];
              if (result['options'] != null) {
                _currentOptionsEn = (result['options'] as List).map((e) => e.toString()).toList();
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  Widget _buildLanguagePanel(String lang) {
    final isEn = lang == 'en';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shared Question Text (for Single Choice, Multi Choice, True/False)
          // 1. Shared Question Text (for Single Choice, Multi Choice, True/False, Relation Analysis)
          if (_questionType != 'matching') ...[
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
                targetCtrl: isEn ? _textControllerEn : _textControllerHu,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Type-Specific Editor
          _buildTypeSpecificEditor(lang),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // 3. Explanation (Shared)
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
              targetCtrl: isEn ? _explanationControllerEn : _explanationControllerHu,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificEditor(String lang) {
    switch (_questionType) {
      case 'relation_analysis':
        return _buildRelationAnalysisEditor(lang);
      case 'matching':
        return _buildMatchingEditor(lang);
      case 'multiple_choice':
        return _buildMultipleChoiceEditor(lang);
      case 'true_false':
        return _buildTrueFalseEditor(lang);
      default:
        return _buildSingleChoiceEditor(lang);
    }
  }

  Widget _buildSingleChoiceEditor(String lang) {
    final isEn = lang == 'en';
    final currentOpts = isEn ? _currentOptionsEn : _currentOptionsHu;
    
    return DynamicOptionList(
      options: currentOpts,
      correctIndex: _correctIndex ?? 0,
      onOptionsChanged: (newOpts) {
        setState(() {
          if (isEn) {
            _currentOptionsEn = newOpts;
          } else {
            _currentOptionsHu = newOpts;
          }
        });
      },
      onCorrectIndexChanged: (idx) => setState(() => _correctIndex = idx),
      onAdd: () {
        setState(() {
          _currentOptionsEn = [..._currentOptionsEn, ''];
          _currentOptionsHu = [..._currentOptionsHu, ''];
        });
      },
      onRemove: (idx) {
        if (_currentOptionsEn.length <= 2) return;
        setState(() {
          _currentOptionsEn = [..._currentOptionsEn]..removeAt(idx);
          _currentOptionsHu = [..._currentOptionsHu]..removeAt(idx);
          if (_correctIndex == idx) {
            _correctIndex = 0;
          } else if (_correctIndex != null && _correctIndex! > idx) {
            _correctIndex = _correctIndex! - 1;
          }
        });
      },
    );
  }

  Widget _buildMultipleChoiceEditor(String lang) {
    final isEn = lang == 'en';
    final currentOpts = isEn ? _currentOptionsEn : _currentOptionsHu;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Options (Select all correct ones)", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        ...List.generate(currentOpts.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _multipleCorrectIndices.contains(index),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _multipleCorrectIndices.add(index);
                      } else {
                        _multipleCorrectIndices.remove(index);
                      }
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: currentOpts[index])..selection = TextSelection.fromPosition(TextPosition(offset: currentOpts[index].length)),
                    onChanged: (val) {
                      if (isEn) {
                        _currentOptionsEn[index] = val;
                      } else {
                        _currentOptionsHu[index] = val;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Option ${index + 1}",
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    if (currentOpts.length <= 2) return;
                    setState(() {
                      _currentOptionsEn.removeAt(index);
                      _currentOptionsHu.removeAt(index);
                      _multipleCorrectIndices.remove(index);
                      // Adjust indices > deleted
                      for (int i=0; i<_multipleCorrectIndices.length; i++) {
                        if (_multipleCorrectIndices[i] > index) _multipleCorrectIndices[i]--;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() {
            _currentOptionsEn.add("");
            _currentOptionsHu.add("");
          }),
          icon: const Icon(Icons.add),
          label: const Text("Add Option"),
        ),
      ],
    );
  }

  Widget _buildRelationAnalysisEditor(String lang) {
    
    // Logic for Simplified 3-State Toggle
    // Map _correctIndex (A=0 ... E=4) to booleans
    // A (0): T, T, Link
    // B (1): T, T, NoLink
    // C (2): T, F
    // D (3): F, T
    // E (4): F, F
    
    bool s1 = false;
    bool s2 = false;
    bool link = false;
    
    // Current State Reading
    int idx = _correctIndex ?? 0;
    if ([0, 1, 2].contains(idx)) s1 = true;
    if ([0, 1, 3].contains(idx)) s2 = true;
    if (idx == 0) link = true;

    // Helper to calculate new index
    int calculateIndex(bool s1, bool s2, bool link) {
       if (s1 && s2) return link ? 0 : 1;
       if (s1 && !s2) return 2;
       if (!s1 && s2) return 3;
       return 4; // E
    }

    return Column(
      children: [
        const Text("Set Correct Logic", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),

        // Toggle S1
        InkWell(
          onTap: () => setState(() => _correctIndex = calculateIndex(!s1, s2, link)),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(s1 ? Icons.check_box : Icons.check_box_outline_blank, color: s1 ? Colors.green : Colors.grey),
              const SizedBox(width: 12),
              const Text("Statement 1 is TRUE"),
            ]),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Toggle S2
        InkWell(
          onTap: () => setState(() => _correctIndex = calculateIndex(s1, !s2, link)),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(s2 ? Icons.check_box : Icons.check_box_outline_blank, color: s2 ? Colors.green : Colors.grey),
              const SizedBox(width: 12),
              const Text("Statement 2 is TRUE"),
            ]),
          ),
        ),

        const SizedBox(height: 12),
        
        // Toggle Link
        // Only valid if both true? Logic says A/B differentiation depends on this.
        Opacity(
          opacity: (s1 && s2) ? 1.0 : 0.5,
          child: InkWell(
            onTap: () {
               if (s1 && s2) setState(() => _correctIndex = calculateIndex(s1, s2, !link));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(link ? Icons.link : Icons.link_off, color: link ? Colors.orange : Colors.grey),
                const SizedBox(width: 12),
                const Text("Connection / Link Exists (Because...)"),
              ]),
            ),
          ),
        ),
        
      ],
    );
  }

  Widget _buildTrueFalseEditor(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("TRUE"),
          labelStyle: TextStyle(
            color: _correctIndex == 0 ? Colors.white : CozyTheme.primary,
            fontWeight: FontWeight.bold,
          ),
          selected: _correctIndex == 0,
          selectedColor: CozyTheme.primary,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: CozyTheme.primary),
          ),
          onSelected: (val) => setState(() => _correctIndex = 0),
        ),
        const SizedBox(width: 24),
        ChoiceChip(
          label: const Text("FALSE"),
           labelStyle: TextStyle(
            color: _correctIndex == 1 ? Colors.white : CozyTheme.accent,
            fontWeight: FontWeight.bold,
          ),
          selected: _correctIndex == 1,
          selectedColor: CozyTheme.accent,
           backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: CozyTheme.accent),
          ),
          onSelected: (val) => setState(() => _correctIndex = 1),
        ),
      ],
    );
  }

  Widget _buildMatchingEditor(String lang) {
    final isEn = lang == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("1-to-1 Matching Pairs", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._matchingGroups.asMap().entries.map((entry) {
          final idx = entry.key;
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: isEn ? group.leftEn : group.leftHu,
                    decoration: InputDecoration(labelText: "Left ${idx+1}", border: const OutlineInputBorder()),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.link)),
                Expanded(
                  child: TextField(
                    controller: isEn ? group.rightEn : group.rightHu,
                    decoration: InputDecoration(labelText: "Right ${idx+1}", border: const OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _matchingGroups.removeAt(idx)),
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () => setState(() => _matchingGroups.add(MatchingPairControllerGroup())),
          icon: const Icon(Icons.add),
          label: const Text("Add Pair"),
        ),
      ],
    );
  }

  Future<void> _translateField({
    required String from, 
    required String to, 
    required TextEditingController sourceCtrl, 
    required TextEditingController targetCtrl
  }) async {
    if (sourceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Source field is empty!")));
      return;
    }
    
    setState(() => _isTranslating = true);
    try {
      final translated = await _translationService.translateText(sourceCtrl.text, from, to);
      if (translated != null) {
        setState(() => targetCtrl.text = translated);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Translation failed")));
        }
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
    
    Map<String, dynamic> contentPayload = {
      'image_url': _existingImageUrl,
    };

    dynamic correctAnswerPayload;

    if (_questionType == 'relation_analysis') {
      contentPayload['statement1'] = {'en': _s1EnController.text, 'hu': _s1HuController.text};
      contentPayload['statement2'] = {'en': _s2EnController.text, 'hu': _s2HuController.text};
      contentPayload['link_word'] = {'en': _linkEnController.text, 'hu': _linkHuController.text};
      correctAnswerPayload = String.fromCharCode('A'.codeUnitAt(0) + (_correctIndex ?? 0));
    } else if (_questionType == 'matching') {
      final List<Map<String, dynamic>> pairs = [];
      final Map<String, String> correctMap = {};
      for (var group in _matchingGroups) {
        pairs.add({
          'left': {'en': group.leftEn.text, 'hu': group.leftHu.text},
          'right': {'en': group.rightEn.text, 'hu': group.rightHu.text},
        });
        if (group.leftEn.text.isNotEmpty) {
          correctMap[group.leftEn.text] = group.rightEn.text;
        }
      }
      contentPayload['pairs'] = pairs;
      correctAnswerPayload = correctMap;
    } else if (_questionType == 'multiple_choice') {
      correctAnswerPayload = _multipleCorrectIndices.map((idx) => _currentOptionsEn[idx]).toList();
      contentPayload['is_multi'] = true;
    } else if (_questionType == 'true_false') {
      contentPayload['statement'] = {'en': _textControllerEn.text, 'hu': _textControllerHu.text};
      correctAnswerPayload = (_correctIndex == 0) ? 'true' : 'false';
    } else {
      // Single Choice
      correctAnswerPayload = _currentOptionsEn[_correctIndex ?? 0];
    }
    
    final payload = {
      'question_text_en': _textControllerEn.text,
      'question_text_hu': _textControllerHu.text,
      'options_en': _currentOptionsEn,
      'options_hu': _currentOptionsHu,
      'explanation_en': _explanationControllerEn.text,
      'explanation_hu': _explanationControllerHu.text,
      'correct_answer': correctAnswerPayload,
      
      // Meta
      'question_type': _questionType,
      'topic_id': _selectedTopicId,
      'bloom_level': _bloomLevel,
      'content': contentPayload,
    };

    final stats = Provider.of<StatsProvider>(context, listen: false);
    
    // Upload Image if selected
    if (_selectedImage != null) {
       // setState(() => _isUploading = true); // Removed unused assignment
       final url = await ApiService().uploadImage(_selectedImage!);
       if (url != null) {
          (payload['content'] as Map)['image_url'] = url;
       }
       // setState(() => _isUploading = false); // Removed unused assignment
    }

    if (!mounted) return;
    bool success = false;
    
    if (widget.question == null) {
      success = await stats.createQuestion(payload);
    } else {
      success = await stats.updateQuestion(widget.question!.id, payload);
    }

    if (success) {
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save question")),
        );
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
                             if (mounted) {
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
