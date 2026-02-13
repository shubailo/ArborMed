import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/stats_provider.dart';
import '../../../services/auth_provider.dart';
import '../../../theme/cozy_theme.dart';
import 'components/user_history_dialog.dart';
import '../../../generated/l10n/app_localizations.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = false;
  bool _isStudentView = true;
  int _currentPage = 1;
  static const int _pageSize = 50;
  DateTime? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    if (_isStudentView) {
      stats.fetchUsersPerformance(
          page: _currentPage, limit: _pageSize, search: _searchQuery);
    } else {
      stats.fetchAdminsPerformance(
          page: _currentPage, limit: _pageSize, search: _searchQuery);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer = DateTime.now();
    final currentTimer = _debounceTimer;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && currentTimer == _debounceTimer) {
        setState(() {
          _searchQuery = value;
          _currentPage = 1;
        });
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatsProvider>(context);

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
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
    final usersList =
        _isStudentView ? stats.usersPerformance : stats.adminsPerformance;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupMenuButton<bool>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                setState(() {
                  _isStudentView = val;
                  _searchQuery = '';
                  _currentPage = 1; // Reset page
                });
                _loadData(); // Re-load for new view
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 20,
                          color: CozyTheme.of(context, listen: false).primary),
                      const SizedBox(width: 12),
                      Text(l10n.adminStudents,
                          style: GoogleFonts.quicksand(
                              color: CozyTheme.of(context, listen: false)
                                  .textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(l10n.adminAdministrators,
                          style: GoogleFonts.quicksand(
                              color: CozyTheme.of(context, listen: false)
                                  .textPrimary)),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isStudentView ? l10n.adminStudents : l10n.adminAdministrators,
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
              _isStudentView
                  ? l10n.adminMedicalRegistry
                  : "${usersList.fold<int>(0, (sum, user) => sum + (user.questionsUploaded ?? 0))} ${l10n.adminQuestionsUploaded} ${l10n.adminByAdmins(usersList.length)}",
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: CozyTheme.of(context).textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Stats Chip
        _buildStatusChip(
            "${_isStudentView ? stats.totalStudents : stats.totalAdmins} ${l10n.adminActiveUsers}"),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CozyTheme.of(context).shadowSmall,
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 13,
          color: CozyTheme.of(context).textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildManagementView(StatsProvider provider) {
    final usersList =
        _isStudentView ? provider.usersPerformance : provider.adminsPerformance;

    var filtered = usersList.where((user) {
      if (_isStudentView) {
        return user.id.toString().contains(_searchQuery);
      }
      return user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Re-apply sorting to filtered list
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'activity':
            comparison = (a.lastActivity ?? DateTime(1970))
                .compareTo(b.lastActivity ?? DateTime(1970));
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
                  ? Center(
                      child: CircularProgressIndicator(
                          color: CozyTheme.of(context).primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Text(l10n.adminNoUsersFound,
                                  style: GoogleFonts.quicksand(
                                      color: CozyTheme.of(context)
                                          .textSecondary))))
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: isMobile
                                    ? _buildMobileCards(
                                        filtered, _isStudentView)
                                    : _buildPerformanceTable(
                                        filtered, _isStudentView),
                              ),
                            ),
                            _buildPaginationFooter(provider),
                          ],
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
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.adminSearchById,
              prefixIcon: Icon(Icons.search,
                  color: CozyTheme.of(context).textSecondary),
              filled: true,
              fillColor: CozyTheme.of(context).paperWhite,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCards(List<UserPerformance> users, bool isStudentMode) {
    return Column(
      children: users
          .map((user) => _buildMobileUserCard(user, isStudentMode))
          .toList(),
    );
  }

  Widget _buildMobileUserCard(UserPerformance user, bool isStudentMode) {
    return Card(
      margin: const EdgeInsets.all(0).copyWith(bottom: 12),
      child: ExpansionTile(
        subtitle: Text(
            isStudentMode
                ? l10n.adminStudentAccount
                : "${user.assignedSubjectName ?? l10n.adminNoSubjectAssigned} • ${user.questionsUploaded ?? 0} ${l10n.adminQuestionsUploaded}",
            style: const TextStyle(fontSize: 12)),
        leading: CircleAvatar(
          backgroundColor: CozyTheme.of(context).primary.withValues(alpha: 0.1),
          child: Text(
              isStudentMode
                  ? "M"
                  : (user.email.isNotEmpty ? user.email[0].toUpperCase() : "A"),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CozyTheme.of(context).primary)),
        ),
        title: Text(
            isStudentMode
                ? "Medical ID: #${user.id.toString().padLeft(3, '0')}"
                : user.email,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          _buildActionRow(user, isStudentMode),
          if (isStudentMode)
            ListTile(
              dense: true,
              title: Text(l10n.adminViewPerformance),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showUserHistory(user, isStudentMode),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable(
      List<UserPerformance> users, bool isStudentMode) {
    return Container(
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
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
              color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            children: [
              _buildHeaderCell(l10n.adminUsers),
              _buildHeaderCell('PATHOPHYS', sortKey: 'pathophysiology'),
              _buildHeaderCell('PATHOLOGY', sortKey: 'pathology'),
              _buildHeaderCell('MICROBIO', sortKey: 'microbiology'),
              _buildHeaderCell('PHARMACO', sortKey: 'pharmacology'),
              _buildHeaderCell(l10n.quizECG, sortKey: 'ecg'),
              _buildHeaderCell(l10n.quizResults, sortKey: 'cases'),
              _buildHeaderCell(l10n.adminTableActivity, sortKey: 'activity'),
              _buildHeaderCell(l10n.adminTableActions),
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
        onTap: sortKey != null
            ? () {
                setState(() {
                  if (_sortColumn == sortKey) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = sortKey;
                    _sortAscending =
                        false; // Default to descending (highest first)
                  }
                });
              }
            : null,
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
                  color: isActive
                      ? CozyTheme.of(context).primary
                      : CozyTheme.of(context).textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (sortKey != null) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive
                      ? (_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 14,
                  color: isActive
                      ? CozyTheme.of(context).primary
                      : CozyTheme.of(context)
                          .textSecondary
                          .withValues(alpha: 0.5),
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
        border: Border(
            bottom: BorderSide(
                color:
                    CozyTheme.of(context).textSecondary.withValues(alpha: 0.1),
                width: 1)),
      ),
      children: [
        _buildStudentCell(user, isStudentMode),
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isSuperAdmin = auth.user?.email == 'shubailobeid@gmail.com';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.mail_outline,
              size: 18, color: Colors.blueAccent),
          onPressed: () => _showMessageDialog(user, isStudentMode),
          tooltip: l10n.adminSendPager,
        ),
        // Show promote/demote button based on super admin status
        if (isStudentMode || isSuperAdmin)
          IconButton(
            icon: Icon(
              isStudentMode
                  ? Icons.shield_outlined
                  : Icons.remove_moderator_outlined,
              size: 18,
              color: isStudentMode
                  ? Colors.orange
                  : (isSuperAdmin ? Colors.orange : Colors.grey),
            ),
            onPressed: isStudentMode || isSuperAdmin
                ? () => _confirmRoleChange(
                    user, isStudentMode ? 'admin' : 'student', isStudentMode)
                : null,
            tooltip: isStudentMode
                ? l10n.adminPromoteAdmin
                : (isSuperAdmin ? l10n.adminDemoteStudent : "Super Admin Only"),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              size: 18, color: Colors.redAccent),
          onPressed: () => _confirmDeletion(user, isStudentMode),
          tooltip: l10n.adminDeleteUser,
        ),
      ],
    );
  }

  // --- HELPER DIALOGS ---

  void _showMessageDialog(UserPerformance user, bool isStudentMode) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.adminPagerTitle(identifier)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
              hintText: l10n.adminTypePagerMessage),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await Provider.of<StatsProvider>(context, listen: false)
                      .sendDirectMessage(user.id, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminMessageDispatched)));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary),
            child: Text(l10n.sent, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRoleChange(
      UserPerformance user, String newRole, bool isStudentMode) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminChangeRole),
        content: Text(
            l10n.adminConfirmRoleChange(identifier, newRole)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<StatsProvider>(context, listen: false)
                      .updateUserRole(user.id, newRole);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminUserRoleUpdated)));
                }
              }
            },
            child: Text(l10n.success.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _confirmDeletion(UserPerformance user, bool isStudentMode) {
    final identifier =
        isStudentMode ? "#${user.id.toString().padLeft(3, '0')}" : user.email;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteUserTitle),
        content: Text(
            l10n.adminDeleteUserConfirm(identifier)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await Provider.of<StatsProvider>(context, listen: false)
                      .deleteUser(user.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.adminDoctorRemoved)));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete.toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  TableCell _buildStudentCell(UserPerformance user, bool isStudentMode) {
    return TableCell(
      child: InkWell(
        onTap: () => _showUserHistory(user, isStudentMode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isStudentMode
                        ? "M"
                        : (user.email.isNotEmpty
                            ? user.email[0].toUpperCase()
                            : "A"),
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: CozyTheme.of(context).primary,
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
                      isStudentMode
                          ? "Medical ID: #${user.id.toString().padLeft(3, '0')}"
                          : user.email,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CozyTheme.of(context).textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.adminClickHistory,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: CozyTheme.of(context).accent,
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
        ? (subject.avgScore >= 70
            ? Colors.green
            : (subject.avgScore >= 50 ? Colors.orange : Colors.red))
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
            lastActivity != null ? timeago.format(lastActivity) : AppLocalizations.of(context)!.adminNever,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: CozyTheme.of(context).textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(StatsProvider stats) {
    final total = _isStudentView ? stats.totalStudents : stats.totalAdmins;
    final totalPages = (total / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
          ),
          Text(
            AppLocalizations.of(context)!.adminPageOf(_currentPage, totalPages),
            style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: CozyTheme.of(context).textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showUserHistory(UserPerformance user, bool isStudentMode) {
    showDialog(
      context: context,
      builder: (context) =>
          UserHistoryDialog(user: user, isStudentMode: isStudentMode),
    );
  }
}
