import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/stats_provider.dart';
import '../../../theme/cozy_theme.dart';

class AdminCommandCenter extends StatefulWidget {
  final Function(int) onNavigate;
  final Function(String) onAction;
  final VoidCallback onExit;

  const AdminCommandCenter({
    super.key,
    required this.onNavigate,
    required this.onAction,
    required this.onExit,
  });

  @override
  State<AdminCommandCenter> createState() => _AdminCommandCenterState();
}

class _AdminCommandCenterState extends State<AdminCommandCenter> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_CommandItem> _filteredCommands = [];
  List<dynamic> _entityResults = []; // NEW: For Users/Questions
  int _selectedIndex = 0;
  bool _showHelp = false;
  bool _isSearching = false; // NEW
  DateTime? _debounceTimer; // NEW

  final List<_CommandItem> _allCommands = [
    _CommandItem(title: 'Go to Dashboard', shortcut: 'Ctrl+D', icon: Icons.dashboard, action: (ctx, state) => state.widget.onNavigate(0)),
    _CommandItem(title: 'Go to Questions', shortcut: 'Ctrl+Q', icon: Icons.question_answer, action: (ctx, state) => state.widget.onNavigate(1)),
    _CommandItem(title: 'Go to Users', shortcut: 'Ctrl+U', icon: Icons.people, action: (ctx, state) => state.widget.onNavigate(2)),
    _CommandItem(title: 'Go to Quotes', shortcut: 'Ctrl+L', icon: Icons.format_quote, action: (ctx, state) => state.widget.onNavigate(3)),
    _CommandItem(title: 'New Question', shortcut: 'Ctrl+N', icon: Icons.add_circle_outline, action: (ctx, state) => state.widget.onAction('new_question')),
    _CommandItem(title: 'New ECG Case', shortcut: 'Ctrl+E', icon: Icons.monitor_heart, action: (ctx, state) => state.widget.onAction('new_ecg')),
    _CommandItem(title: 'Exit Admin', shortcut: 'ESC', icon: Icons.exit_to_app, action: (ctx, state) => state.widget.onExit()),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCommands = _allCommands;
    _focusNode.requestFocus();
  }

  void _filterCommands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = _allCommands;
        _entityResults = [];
      } else {
        _filteredCommands = _allCommands
            .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        
        if (query.length >= 2) {
          _performEntitySearch(query);
        } else {
          _entityResults = [];
        }
      }
      _selectedIndex = 0;
    });
  }

  Future<void> _performEntitySearch(String query) async {
    _debounceTimer = DateTime.now();
    final currentTimer = _debounceTimer;
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (currentTimer != _debounceTimer || !mounted) return;

    setState(() => _isSearching = true);
    try {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      
      if (query.startsWith('@')) {
        // User Search
        final email = query.substring(1);
        await stats.fetchUsersPerformance(search: email);
        if (mounted) setState(() => _entityResults = stats.usersPerformance);
      } else if (query.startsWith('#')) {
        // Question Search
        final qText = query.substring(1);
        await stats.fetchAdminQuestions(search: qText);
        if (mounted) setState(() => _entityResults = stats.adminQuestions);
      } else {
        // Search both if general query
        await stats.fetchUsersPerformance(search: query);
        await stats.fetchAdminQuestions(search: query);
        if (mounted) {
          setState(() {
             _entityResults = [...stats.usersPerformance, ...stats.adminQuestions];
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_filteredCommands.isNotEmpty) {
          _executeCommand(_filteredCommands[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      } else if (event.logicalKey == LogicalKeyboardKey.f10) {
        setState(() => _showHelp = !_showHelp);
      }
    }
  }

  void _executeCommand(_CommandItem command) {
    command.action(context, this);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Combined list: Commands first, then Entities
    final allItems = [..._filteredCommands, ..._entityResults];
    
    return Material(
      type: MaterialType.transparency,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
            child: Container(
              width: 600,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _filterCommands,
                      decoration: InputDecoration(
                        hintText: 'Search commands (@user, #question)...',
                        prefixIcon: const Icon(Icons.search, color: CozyTheme.textSecondary),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_showHelp ? null : const Text('F10 for help  ', style: TextStyle(color: Colors.grey, fontSize: 10))),
                        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Divider(height: 1),

                  if (_showHelp) ...[
                    _buildHelpSection(),
                  ] else ...[
                    // Results List
                    Flexible(
                      child: allItems.isEmpty && _searchController.text.isNotEmpty && !_isSearching
                          ? _buildNoResults()
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: allItems.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final item = allItems[index];
                                final isSelected = index == _selectedIndex;

                                if (item is _CommandItem) {
                                  return _buildCommandTile(item, isSelected);
                                } else if (item is UserPerformance) {
                                  return _buildUserTile(item, isSelected);
                                } else if (item is AdminQuestion) {
                                  return _buildQuestionTile(item, isSelected);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                    ),
                  ],

                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildShortcutHint('↑↓', 'Navigate'),
                        const SizedBox(width: 16),
                        _buildShortcutHint('Enter', 'Select'),
                        const SizedBox(width: 16),
                        _buildShortcutHint('Esc', 'Close'),
                        const Spacer(),
                        const Text('Admin Power Center', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No matching commands or data found', style: GoogleFonts.quicksand(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCommandTile(_CommandItem command, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? CozyTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(command.icon, color: isSelected ? CozyTheme.primary : CozyTheme.textSecondary, size: 20),
        title: Text(command.title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: isSelected ? CozyTheme.primary : CozyTheme.textPrimary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
          child: Text(command.shortcut, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        onTap: () => _executeCommand(command),
      ),
    );
  }

  Widget _buildUserTile(UserPerformance user, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.person, color: Colors.blue, size: 20),
        title: Text(user.email, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        subtitle: Text('Student #${user.id}', style: const TextStyle(fontSize: 10)),
        trailing: const Text('JUMP TO USER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
        onTap: () {
          widget.onNavigate(2);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildQuestionTile(AdminQuestion q, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.help_outline, color: Colors.teal, size: 20),
        title: Text(q.text ?? '(No text)', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        subtitle: Text('Question #${q.id} • ${q.type}', style: const TextStyle(fontSize: 10)),
        trailing: const Text('JUMP TO Q', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
        onTap: () {
          widget.onNavigate(1);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHelpSection() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Keyboard Shortcuts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildHelpRow('Tab', 'Open Command Center'),
            _buildHelpRow('F10', 'Toggle Help'),
            _buildHelpRow('Ctrl + D', 'Go to Dashboard'),
            _buildHelpRow('Ctrl + Q', 'Go to Questions'),
            _buildHelpRow('Ctrl + U', 'Go to Users'),
            _buildHelpRow('Ctrl + L', 'Go to Quotes'),
            _buildHelpRow('Ctrl + N', 'New Question'),
            _buildHelpRow('Ctrl + E', 'New ECG Case'),
            _buildHelpRow('ESC', 'Close Modal'),
            _buildHelpRow('@...', 'Find User by Email'),
            _buildHelpRow('#...', 'Find Question by Text/ID'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _showHelp = false), 
              child: const Text('Back to commands', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(desc, style: const TextStyle(color: CozyTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[300]!)),
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutHint(String key, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
          child: Text(key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _CommandItem {
  final String title;
  final String shortcut;
  final IconData icon;
  final Function(BuildContext, _AdminCommandCenterState) action;

  _CommandItem({required this.title, required this.shortcut, required this.icon, required this.action});
}
