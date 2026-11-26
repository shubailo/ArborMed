import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'smart_review_sheet.dart';
import '../../analytics/models/study_metric.dart';
import 'study_break_icon.dart';
import '../../ecg/screens/ecg_practice_screen.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/services/audio_provider.dart';

enum QuizMenuState { main, subjects, systems }

class QuizMenuWidget extends StatelessWidget {
  final void Function(String name, String slug) onSystemSelected;
  final VoidCallback? onClose;
  const QuizMenuWidget(
      {super.key, required this.onSystemSelected, this.onClose});
  @override
  Widget build(BuildContext context) {
    final revision = context.select((StatsProvider p) => p.sessionRevision);
    return _QuizMenu(
        key: ValueKey(revision),
        onSystemSelected: onSystemSelected,
        session: revision);
  }
}

class _QuizMenu extends StatefulWidget {
  const _QuizMenu(
      {super.key, required this.onSystemSelected, required this.session});
  final void Function(String, String) onSystemSelected;
  final int session;
  @override
  State<_QuizMenu> createState() => _QuizMenuState();
}

class _QuizMenuState extends State<_QuizMenu> {
  QuizMenuState _state = QuizMenuState.main;
  final _path = <SubjectMastery>[];
  bool _reviewOpen = false;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StatsProvider>().fetchCurrentQuote();
    });
  }

  void _select(String name, String slug) {
    if (_selected ||
        widget.session != context.read<StatsProvider>().sessionRevision ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _selected = true;
    widget.onSystemSelected(name, slug);
    // Embedded menus may stay on screen after the callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selected = false;
    });
  }

  Future<void> _showSmartReview() async {
    if (_reviewOpen) return;
    _reviewOpen = true;
    final stats = context.read<StatsProvider>();
    final revision = widget.session;
    try {
      final choice = await showModalBottomSheet<({String name, String slug})>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => ListenableBuilder(
            listenable: stats,
            builder: (context, _) {
              if (stats.sessionRevision != revision) {
                final strings = AppLocalizations.of(context)!;
                return SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(strings.quizReviewSessionEnded),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(strings.close)),
                  ]),
                ));
              }
              return ChangeNotifierProvider.value(
                  value: stats,
                  child: SmartReviewSheet(onReviewSelected: (name, slug) {
                    if (stats.sessionRevision == revision &&
                        ModalRoute.of(sheetContext)?.isCurrent == true) {
                      Navigator.pop(sheetContext, (name: name, slug: slug));
                    }
                  }));
            }),
      );
      if (mounted && choice != null && stats.sessionRevision == revision) {
        _select(choice.name, choice.slug);
      }
    } finally {
      _reviewOpen = false;
    }
  }

  bool get _hu => Localizations.localeOf(context).languageCode == 'hu';
  String _title(SubjectMastery subject) {
    final translated = _hu ? studyText(subject.subjectHu) : '';
    return translated.isEmpty ? subject.subjectEn : translated;
  }

  void _onSubjectTap(SubjectMastery subject) {
    context.read<StatsProvider>().fetchSubjectDetail(subject.slug);
    setState(() {
      _path.add(subject);
      _state = QuizMenuState.systems;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select((StatsProvider p) => (p.readinessState, p.readiness));
    final strings = AppLocalizations.of(context)!;
    return Column(children: [
      if (_state != QuizMenuState.main)
        ListTile(
            leading: const Icon(Icons.arrow_back_ios_new),
            title: Text(
                _state == QuizMenuState.systems
                    ? _title(_path.last)
                    : strings.quizSelectSubject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            onTap: () => setState(() {
                  if (_path.isEmpty) {
                    _state = QuizMenuState.main;
                  } else {
                    _path.removeLast();
                    _state = _path.isEmpty
                        ? QuizMenuState.subjects
                        : QuizMenuState.systems;
                  }
                })),
      Expanded(
          child: switch (_state) {
        QuizMenuState.main => _buildMainMenu(),
        QuizMenuState.subjects => _subjects(),
        QuizMenuState.systems => _sections(_path.last),
      }),
    ]);
  }

  Widget _subjects() {
    final stats = context.watch<StatsProvider>();
    final strings = AppLocalizations.of(context)!;
    if (stats.summaryFailed) {
      return _retry(strings.roundsSummaryRetry, stats.fetchSummary);
    }
    if (stats.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final subjects =
        stats.subjectMastery.where((s) => s.slug.trim().isNotEmpty).toList();
    if (subjects.isEmpty) return Center(child: Text(strings.masteryEmpty));
    return ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: Text(_title(subject)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _onSubjectTap(subject));
        });
  }

  Widget _retry(String text, VoidCallback action) => Center(
      child: TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: Text(text),
          onPressed: action));

  Widget _sections(SubjectMastery subject) {
    final stats = context.watch<StatsProvider>();
    final strings = AppLocalizations.of(context)!;
    final state = stats.getSectionState(subject.slug);
    final rows = (stats.sectionMastery[subject.slug] ?? [])
        .where((r) => studyText(r['slug']).isNotEmpty)
        .toList();
    if (state == SubjectQuizState.error) {
      return _retry(strings.quizSectionsRetry,
          () => stats.fetchSubjectDetail(subject.slug));
    }
    if (state == SubjectQuizState.initial ||
        state == SubjectQuizState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    DateTime? latest;
    String? recent;
    for (final row in rows) {
      final date = DateTime.tryParse(studyText(row['last_studied']));
      if (date != null &&
          (int.tryParse(row['attempts'].toString()) ?? 0) > 0 &&
          (latest == null || date.isAfter(latest))) {
        latest = date;
        recent = studyText(row['slug']);
      }
    }
    final reviewButton = _reviewButton();
    final empty = rows.isEmpty && !subject.hasDirectQuestions;
    return ListView.builder(
        itemCount: 1 +
            (subject.hasDirectQuestions ? 1 : 0) +
            (empty ? 1 : rows.length),
        itemBuilder: (context, index) {
          if (index == 0) return reviewButton;
          if (subject.hasDirectQuestions && index == 1) {
            return ListTile(
                title: Text(strings.quizPracticeSubject),
                leading: const Icon(Icons.school),
                onTap: () => _select(_title(subject), subject.slug));
          }
          if (empty) return Center(child: Text(strings.masteryNoSections));
          final row = rows[index - 1 - (subject.hasDirectQuestions ? 1 : 0)];
          final slug = studyText(row['slug']);
          final name = [
            _hu ? studyText(row['name_hu']) : '',
            studyText(row['name_en']),
            studyText(row['section']),
            slug
          ].firstWhere((s) => s.isNotEmpty);
          final branch = row['has_children'] == true;
          final available = branch || row['has_direct_questions'] != false;
          final attempts = int.tryParse(row['attempts'].toString()) ?? 0;
          final percent = num.tryParse(row['proficiency'].toString());
          return ListTile(
              title: Text(name),
              enabled: available,
              subtitle: !available
                  ? Text(strings.quizNoQuestions)
                  : slug == recent
                      ? Text(strings.quizLastStudied)
                      : null,
              trailing: attempts > 0 && percent != null && percent.isFinite
                  ? Text('${percent.clamp(0, 100).round()}%')
                  : null,
              onTap: !available
                  ? null
                  : () {
                      if (branch) {
                        _onSubjectTap(SubjectMastery.fromJson(row));
                      } else {
                        _select(name, slug);
                      }
                    });
        });
  }

  Widget _reviewButton() {
    final stats = context.read<StatsProvider>();
    final strings = AppLocalizations.of(context)!;
    final readiness = stats.readiness;
    final label = stats.readinessState == ReviewLoadState.ready &&
            readiness != null &&
            readiness.breakdown.isNotEmpty
        ? '${strings.quizReviewTitle} · ${readiness.overall}%'
        : strings.quizReviewTitle;
    return TextButton.icon(
        onPressed: _showSmartReview,
        icon: const Icon(Icons.bolt),
        label: Text(label));
  }

  Widget _buildMainMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10), // Reduced from 20
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final quote = stats.currentQuote;
              // Default to heart if no quote or icon
              final iconName = quote?.iconName ?? 'favorite_rounded';
              final customUrl = quote?.customIconUrl;

              return StudyBreakIcon(iconName: iconName, customUrl: customUrl);
            },
          ),
          const SizedBox(height: 16), // Reduced from 24
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final locale = Localizations.localeOf(context).languageCode;
              final qc = stats.currentQuote;
              String displayTitle = AppLocalizations.of(
                context,
              )!
                  .quizStudyBreak;

              if (qc != null) {
                if (locale == 'hu') {
                  if (qc.titleHu.isNotEmpty) {
                    displayTitle = qc.titleHu;
                  } else if (qc.titleEn.isNotEmpty) {
                    displayTitle = qc.titleEn;
                  }
                } else {
                  if (qc.titleEn.isNotEmpty) {
                    displayTitle = qc.titleEn;
                  }
                }
              }

              return Text(
                displayTitle,
                style: GoogleFonts.quicksand(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CozyTheme.of(context).textPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: 24), // Increased spacing
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final locale = Localizations.localeOf(context).languageCode;
              final quoteText = locale == 'hu'
                  ? (stats.currentQuote?.textHu.isNotEmpty == true
                      ? stats.currentQuote!.textHu
                      : stats.currentQuote?.textEn)
                  : stats.currentQuote?.textEn;
              final displayQuote =
                  quoteText ?? AppLocalizations.of(context)!.quizFallbackQuote;
              final quoteAuthor = stats.currentQuote?.author ?? "ArborMed";

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Text(
                        displayQuote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16, // Reduced from 18
                          color: CozyTheme.of(context).textSecondary,
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 32
                  if (stats.currentQuote != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "- $quoteAuthor",
                        style: TextStyle(
                          fontSize: 12,
                          color: CozyTheme.of(
                            context,
                          ).textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      AppLocalizations.of(context)!.quizQuoteTopic,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CozyTheme.of(context).textSecondary,
                        height: 1.3,
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildGridOption(
                  AppLocalizations.of(context)!.quizSubjects,
                  Icons.library_books_rounded,
                  true,
                  () {
                    final stats = context.read<StatsProvider>();
                    if (!stats.isLoading) stats.fetchSummary();
                    setState(() {
                      _state = QuizMenuState.subjects;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridOption(
                  AppLocalizations.of(context)!.quizECG,
                  Icons.monitor_heart_rounded,
                  true,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ECGPracticeScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridOption(
                  Localizations.localeOf(context).languageCode == 'hu'
                      ? "Esetek"
                      : "Cases",
                  Icons.assignment_rounded,
                  false,
                  () {},
                ),
              ), // Still disabled
            ],
          ),
          _reviewButton(),
          const SizedBox(height: 20), // Reduced from 30
          const SizedBox(height: 10), // Reduced from 20
        ],
      ),
    );
  }

  Widget _buildGridOption(
    String title,
    IconData icon,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    final palette = CozyTheme.of(context);
    final isActive = isEnabled;
    return GestureDetector(
      onTap: isActive
          ? () {
              Provider.of<AudioProvider>(
                context,
                listen: false,
              ).playSfx('click');
              onTap();
            }
          : null,
      child: Container(
        height: 90, // Reduced from 100
        decoration: BoxDecoration(
          color: isActive
              ? palette.paperWhite
              : palette.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? palette.primary
                : palette.textSecondary.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? palette.primary
                  : palette.textSecondary.withValues(alpha: 0.4),
              size: 28,
            ), // Reduced size
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? palette.textPrimary : palette.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12, // Reduced from 13
              ),
            ),
          ],
        ),
      ),
    );
  }
}
