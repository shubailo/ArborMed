import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/models/performance.dart';
import '../../../services/admin_user_provider.dart';
import '../../../services/auth_provider.dart';
import '../../../theme/cozy_theme.dart';
import 'components/user_history_dialog.dart';
import 'components/admin_user_dialogs.dart';
import 'components/admin_timestamp.dart';
import 'components/pagination_footer.dart';
import '../../../generated/l10n/app_localizations.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  String _searchQuery = '';
  String _sortColumn = 'activity';
  bool _sortAscending = false;
  bool _isStudentView = true;
  static const int _pageSize = 50;
  final _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData(page: 1);
    });
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent != true ||
          context.read<AdminUserProvider>().directoryLoading) {
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData({int? page}) {
    final stats = Provider.of<AdminUserProvider>(context, listen: false);
    if (_isStudentView) {
      stats.fetchUsersPerformance(
          page: page ?? stats.directoryPage, limit: _pageSize, search: _searchQuery,
          sort: _sortColumn, ascending: _sortAscending);
    } else {
      stats.fetchAdminsPerformance(
          page: page ?? stats.directoryPage, limit: _pageSize, search: _searchQuery,
          sort: _sortColumn, ascending: _sortAscending);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchQuery = value.trim();
      _loadData(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminUserProvider>(context);

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

  Widget _buildHeader(AdminUserProvider stats) {
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
                _debounce?.cancel();
                _searchController.clear();
                setState(() {
                  _isStudentView = val;
                  _searchQuery = '';
                  _sortColumn = 'activity';
                  _sortAscending = false;
                });
                _loadData(page: 1);
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
                      Flexible(child: Text(l10n.adminStudents,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                              color: CozyTheme.of(context, listen: false)
                                  .textPrimary))),
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
                      Flexible(child: Text(l10n.adminAdministrators,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                              color: CozyTheme.of(context, listen: false)
                                  .textPrimary))),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(
                    _isStudentView ? l10n.adminStudents : l10n.adminAdministrators,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CozyTheme.of(context, listen: false).textPrimary,
                    ),
                  )),
                  const SizedBox(width: 8),
                  Icon(Icons.expand_more,
                      size: 28,
                      color:
                          CozyTheme.of(context, listen: false).textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_isStudentView) Text(
              l10n.adminMedicalRegistry,
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
            "${_isStudentView ? stats.totalStudents : stats.totalAdmins} ${l10n.adminUsers}"),
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

  Widget _buildManagementView(AdminUserProvider provider) {
    final usersList =
        _isStudentView ? provider.usersPerformance : provider.adminsPerformance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return Column(
          children: [
            _buildToolbar(provider),
            const SizedBox(height: 24),
            Expanded(
              child: provider.directoryFailed
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l10n.adminDirectoryLoadFailed),
                      TextButton(onPressed: _loadData, child: Text(l10n.retry)),
                    ]))
                  : provider.directoryLoading && usersList.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                          color: CozyTheme.of(context).primary))
                  : usersList.isEmpty
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
                                        usersList, _isStudentView)
                                    : _buildPerformanceTable(
                                        usersList, _isStudentView),
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

  Widget _buildToolbar(AdminUserProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: _isStudentView ? l10n.adminSearchStudents : l10n.adminSearchAdmins,
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
        IconButton(
          tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
          onPressed: provider.directoryLoading ? null : _loadData,
          icon: const Icon(Icons.refresh),
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

  String _assignedSubject(UserPerformance user) {
    final hu = Localizations.localeOf(context).languageCode == 'hu';
    return (hu ? user.assignedSubjectNameHu : user.assignedSubjectName) ??
        user.assignedSubjectName ?? user.assignedSubjectNameHu ?? l10n.adminNoSubjectAssigned;
  }

  Widget _buildMobileUserCard(UserPerformance user, bool isStudentMode) {
    return Card(
      margin: const EdgeInsets.all(0).copyWith(bottom: 12),
      child: ExpansionTile(
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isStudentMode) Text(
              "${_assignedSubject(user)} • ${user.questionsUploaded ?? 0} ${l10n.adminQuestionsUploaded}",
              style: const TextStyle(fontSize: 12)),
            Text('${l10n.adminTableActivity}: ${adminTimestamp(context, user.lastActivity)}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
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
                ? "${l10n.medicalId} #${user.id.toString().padLeft(3, '0')}"
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
        columnWidths: isStudentMode ? const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.0),
          6: FlexColumnWidth(1.0),
          7: FlexColumnWidth(1.5),
          8: FixedColumnWidth(160), // ACTIONS
        } : const {0: FlexColumnWidth(2), 4: FixedColumnWidth(160)},
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
              if (isStudentMode) ...[
              _buildHeaderCell(l10n.quizSubjectPathophysiology, sortKey: 'pathophysiology'),
              _buildHeaderCell(l10n.quizSubjectPathology, sortKey: 'pathology'),
              _buildHeaderCell(l10n.quizSubjectMicrobiology, sortKey: 'microbiology'),
              _buildHeaderCell(l10n.quizSubjectPharmacology, sortKey: 'pharmacology'),
              _buildHeaderCell(l10n.quizECG, sortKey: 'ecg'),
              _buildHeaderCell(l10n.adminCaseStudies, sortKey: 'cases'),
              ] else ...[
                _buildHeaderCell(l10n.adminSubject),
                _buildHeaderCell(l10n.adminQuestionsUploaded),
              ],
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
                _loadData(page: 1);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? CozyTheme.of(context).primary
                        : CozyTheme.of(context).textSecondary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
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
        if (isStudentMode) ...[
        _buildScoreCell(user.pathophysiology),
        _buildScoreCell(user.pathology),
        _buildScoreCell(user.microbiology),
        _buildScoreCell(user.pharmacology),
        _buildScoreCell(user.ecg),
        _buildScoreCell(user.cases),
        ] else ...[
          Center(child: Text(_assignedSubject(user))),
          Center(child: Text('${user.questionsUploaded ?? 0}')),
        ],
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
    final isSuperAdmin = auth.user?.isSuperAdmin == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.mail_outline,
              size: 18, color: Colors.blueAccent),
          onPressed: () => AdminUserDialogs.showMessageDialog(context, user, isStudentMode),
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
                ? () => AdminUserDialogs.confirmRoleChange(context, user, isStudentMode ? 'admin' : 'student', isStudentMode)
                : null,
            tooltip: isStudentMode
                ? l10n.adminPromoteAdmin
                : (isSuperAdmin ? l10n.adminDemoteStudent : "Super Admin Only"),
          ),
        if (user.id != auth.user?.id && (isStudentMode || isSuperAdmin))
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.redAccent),
            onPressed: () => AdminUserDialogs.confirmDeletion(context, user, isStudentMode),
            tooltip: l10n.adminDeleteUser,
          ),
      ],
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
                          ? "${AppLocalizations.of(context)!.medicalId} #${user.id.toString().padLeft(3, '0')}"
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
            adminTimestamp(context, lastActivity),
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: CozyTheme.of(context).textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(AdminUserProvider stats) {
    return PaginationFooter(
      currentPage: stats.directoryPage,
      totalCount: _isStudentView ? stats.totalStudents : stats.totalAdmins,
      pageSize: _pageSize,
      onPageChanged: (newPage) => _loadData(page: newPage),
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

