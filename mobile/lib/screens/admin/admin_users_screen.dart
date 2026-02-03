import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/stats_provider.dart';
import '../../../theme/cozy_theme.dart';
import 'components/user_history_dialog.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = false;
  bool _isStudentView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    stats.fetchUsersPerformance();
    stats.fetchAdminsPerformance();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatsProvider>(context);
    
    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider),
            const SizedBox(height: 24),
            Expanded(
              child: _buildManagementView(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StatsProvider stats) {
    final usersList = _isStudentView ? stats.usersPerformance : stats.adminsPerformance;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupMenuButton<bool>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                setState(() {
                  _isStudentView = val;
                  _searchQuery = '';
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 20, color: CozyTheme.primary),
                      const SizedBox(width: 12),
                      Text("Students", style: GoogleFonts.quicksand(color: CozyTheme.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, size: 20, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text("Administrators", style: GoogleFonts.quicksand(color: CozyTheme.textPrimary)),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isStudentView ? "Students" : "Administrators",
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
              _isStudentView ? "Medical Student Registry & Performance" : "Hospital Administration & System Access",
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: CozyTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Stats Chip
        _buildStatusChip("${usersList.length} Active Users"),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildManagementView(StatsProvider provider) {
    final usersList = _isStudentView ? provider.usersPerformance : provider.adminsPerformance;
    
    var filtered = usersList.where((user) {
      return user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Re-apply sorting to filtered list
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'activity':
            comparison = (a.lastActivity ?? DateTime(1970)).compareTo(b.lastActivity ?? DateTime(1970));
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Column(
          children: [
            _buildToolbar(isMobile),
            const SizedBox(height: 24),
            Expanded(
              child: provider.isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(48), child: Text("No users found", style: GoogleFonts.quicksand(color: CozyTheme.textSecondary))))
                  : SingleChildScrollView(
                      child: isMobile 
                        ? _buildMobileCards(filtered, _isStudentView) 
                        : _buildPerformanceTable(filtered, _isStudentView),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by email or name...',
              prefixIcon: const Icon(Icons.search, color: CozyTheme.textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMobileCards(List<UserPerformance> users, bool isStudentMode) {
    return Column(
      children: users.map((user) => _buildMobileUserCard(user, isStudentMode)).toList(),
    );
  }

  Widget _buildMobileUserCard(UserPerformance user, bool isStudentMode) {
    return Card(
      margin: const EdgeInsets.all(0).copyWith(bottom: 12),
      child: ExpansionTile(
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        leading: CircleAvatar(
          backgroundColor: CozyTheme.primary.withValues(alpha: 0.1),
          child: Text(user.email[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.primary)),
        ),
        title: Text(user.email.split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          _buildActionRow(user, isStudentMode),
          ListTile(
            dense: true,
            title: const Text("View Performance History"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUserHistory(user),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable(List<UserPerformance> users, bool isStudentMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.0),
          6: FlexColumnWidth(1.0),
          7: FlexColumnWidth(1.5),
          8: FixedColumnWidth(160), // ACTIONS
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              color: CozyTheme.textPrimary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            children: [
              _buildHeaderCell('STUDENT'),
              _buildHeaderCell('PATHOPHYS', sortKey: 'pathophysiology'),
              _buildHeaderCell('PATHOLOGY', sortKey: 'pathology'),
              _buildHeaderCell('MICROBIO', sortKey: 'microbiology'),
              _buildHeaderCell('PHARMACO', sortKey: 'pharmacology'),
              _buildHeaderCell('ECG', sortKey: 'ecg'),
              _buildHeaderCell('CASES', sortKey: 'cases'),
              _buildHeaderCell('ACTIVITY', sortKey: 'activity'),
              _buildHeaderCell('ACTIONS'),
            ],
          ),
          
          // Data Rows
          ...users.map((user) => _buildUserRow(user, isStudentMode)),
        ],
      ),
    );
  }

  TableCell _buildHeaderCell(String label, {String? sortKey}) {
    final isActive = _sortColumn == sortKey;
    
    return TableCell(
      child: InkWell(
        onTap: sortKey != null ? () {
          setState(() {
            if (_sortColumn == sortKey) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = sortKey;
              _sortAscending = false; // Default to descending (highest first)
            }
          });
        } : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? CozyTheme.primary : CozyTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (sortKey != null) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive 
                    ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.unfold_more,
                  size: 14,
                  color: isActive ? CozyTheme.primary : CozyTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildUserRow(UserPerformance user, bool isStudentMode) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CozyTheme.textSecondary.withValues(alpha: 0.1), width: 1)),
      ),
      children: [
        _buildStudentCell(user),
        _buildScoreCell(user.pathophysiology),
        _buildScoreCell(user.pathology),
        _buildScoreCell(user.microbiology),
        _buildScoreCell(user.pharmacology),
        _buildScoreCell(user.ecg),
        _buildScoreCell(user.cases),
        _buildActivityCell(user.lastActivity),
        _buildActionCell(user, isStudentMode),
      ],
    );
  }

  TableCell _buildActionCell(UserPerformance user, bool isStudentMode) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: _buildActionRow(user, isStudentMode),
    );
  }

  Widget _buildActionRow(UserPerformance user, bool isStudentMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.mail_outline, size: 18, color: Colors.blueAccent),
          onPressed: () => _showMessageDialog(user),
          tooltip: "Send Pager Message",
        ),
        IconButton(
          icon: Icon(
            isStudentMode ? Icons.shield_outlined : Icons.remove_moderator_outlined,
            size: 18,
            color: Colors.orange,
          ),
          onPressed: () => _confirmRoleChange(user, isStudentMode ? 'admin' : 'student'),
          tooltip: isStudentMode ? "Promote to Admin" : "Demote to Student",
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
          onPressed: () => _confirmDeletion(user),
          tooltip: "Delete User",
        ),
      ],
    );
  }

  // --- HELPER DIALOGS ---

  void _showMessageDialog(UserPerformance user) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("PAGER: ${user.email}"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Type your message to the student..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(context, listen: false).sendDirectMessage(user.id, controller.text);
              if (mounted) Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message dispatched!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CozyTheme.primary),
            child: const Text("SEND", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRoleChange(UserPerformance user, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Role?"),
        content: Text("Are you sure you want to change Dr. ${user.email}'s role to $newRole?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(context, listen: false).updateUserRole(user.id, newRole);
              if (mounted) Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User role updated!")));
              }
            },
            child: const Text("YES, CHANGE"),
          ),
        ],
      ),
    );
  }

  void _confirmDeletion(UserPerformance user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permanently Delete User?"),
        content: Text("This will erase ALL progress for Dr. ${user.email}. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(context, listen: false).deleteUser(user.id);
              if (mounted) Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor removed from registry.")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  TableCell _buildStudentCell(UserPerformance user) {
    return TableCell(
      child: InkWell(
        onTap: () => _showUserHistory(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CozyTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.email[0].toUpperCase(),
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: CozyTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CozyTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Click for history',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: CozyTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableCell _buildScoreCell(SubjectPerformance subject) {
    final bool hasData = subject.totalQuestions > 0;
    final Color scoreColor = hasData
        ? (subject.avgScore >= 70 ? Colors.green : (subject.avgScore >= 50 ? Colors.orange : Colors.red))
        : Colors.grey;

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Tooltip(
          message: hasData
              ? 'Answered: ${subject.totalQuestions}\nCorrect: ${subject.correctQuestions}\nAvg Time: ${(subject.avgTimeMs / 1000).toStringAsFixed(1)}s'
              : 'No attempts yet',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  hasData ? '${subject.avgScore}%' : '—',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: scoreColor.withValues(alpha: 0.2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: subject.avgScore / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableCell _buildActivityCell(DateTime? lastActivity) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: Text(
            lastActivity != null ? timeago.format(lastActivity) : 'Never',
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: CozyTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showUserHistory(UserPerformance user) {
    showDialog(
      context: context,
      builder: (context) => UserHistoryDialog(user: user),
    );
  }
}
