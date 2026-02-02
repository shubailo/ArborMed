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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<StatsProvider>(context, listen: false).fetchUsersPerformance();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatsProvider>(context);
    var users = provider.usersPerformance.where((user) {
      return user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply sorting
    if (_sortColumn != null) {
      users.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'pathophysiology':
            comparison = a.pathophysiology.avgScore.compareTo(b.pathophysiology.avgScore);
            break;
          case 'pathology':
            comparison = a.pathology.avgScore.compareTo(b.pathology.avgScore);
            break;
          case 'microbiology':
            comparison = a.microbiology.avgScore.compareTo(b.microbiology.avgScore);
            break;
          case 'pharmacology':
            comparison = a.pharmacology.avgScore.compareTo(b.pharmacology.avgScore);
            break;
          case 'ecg':
            comparison = a.ecg.avgScore.compareTo(b.ecg.avgScore);
            break;
          case 'cases':
            comparison = a.cases.avgScore.compareTo(b.cases.avgScore);
            break;
          case 'activity':
            comparison = (a.lastActivity ?? DateTime(1970)).compareTo(b.lastActivity ?? DateTime(1970));
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }


    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(users, isMobile),
                  const SizedBox(height: 24),
                  
                  // Performance Table or Cards
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (users.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Text(
                          'No students found',
                          style: GoogleFonts.quicksand(color: CozyTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    isMobile ? _buildMobileCards(users) : _buildPerformanceTable(users),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<UserPerformance> users, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Performance',
                  style: GoogleFonts.quicksand(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: CozyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${users.length} students',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: CozyTheme.textSecondary,
                  ),
                ),
              ],
            ),
            // Search Field
            if (!isMobile)
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search, color: CozyTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, color: CozyTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileCards(List<UserPerformance> users) {
    return Column(
      children: users.map((user) => _buildMobileUserCard(user)).toList(),
    );
  }

  Widget _buildMobileUserCard(UserPerformance user) {
    // Find best subject
    final subjects = [
      ('Pathophysiology', user.pathophysiology),
      ('Pathology', user.pathology),
      ('Microbiology', user.microbiology),
      ('Pharmacology', user.pharmacology),
      ('ECG', user.ecg),
      ('Cases', user.cases),
    ];
    final best = subjects.where((s) => s.$2.totalQuestions > 0).fold<(String, SubjectPerformance)?>(null, (prev, curr) {
      if (prev == null || curr.$2.avgScore > prev.$2.avgScore) return curr;
      return prev;
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserHistory(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CozyTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.email[0].toUpperCase(),
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CozyTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.lastActivity != null ? timeago.format(user.lastActivity!) : 'Never active',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: CozyTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (best != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (best.$2.avgScore >= 70 ? Colors.green : (best.$2.avgScore >= 50 ? Colors.orange : Colors.red)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Best: ${best.$1}',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CozyTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${best.$2.avgScore}%',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: best.$2.avgScore >= 70 ? Colors.green : (best.$2.avgScore >= 50 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Tap to view full history',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: CozyTheme.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceTable(List<UserPerformance> users) {
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
          0: FlexColumnWidth(2.5), // Student
          1: FlexColumnWidth(1.2), // Pathophysiology
          2: FlexColumnWidth(1.2), // Pathology
          3: FlexColumnWidth(1.2), // Microbiology
          4: FlexColumnWidth(1.2), // Pharmacology
          5: FlexColumnWidth(1.0), // ECG
          6: FlexColumnWidth(1.0), // Cases
          7: FlexColumnWidth(1.5), // Last Activity
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
              _buildHeaderCell('LAST ACTIVITY', sortKey: 'activity'),
            ],
          ),
          
          // Data Rows
          ...users.map((user) => _buildUserRow(user)),
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

  TableRow _buildUserRow(UserPerformance user) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CozyTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
      ],
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
