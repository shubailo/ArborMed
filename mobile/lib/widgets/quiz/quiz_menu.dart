import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../cozy/cozy_tile.dart';
import '../../services/stats_provider.dart';
import 'smart_review_sheet.dart'; // NEW IMPORT
import '../../screens/ecg_practice_screen.dart';
import 'package:mobile/generated/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/sync_service.dart';
import '../../theme/cozy_theme.dart';

enum QuizMenuState { main, subjects, systems }

class QuizMenuWidget extends StatefulWidget {
  final Function(String name, String slug) onSystemSelected;
  final VoidCallback? onClose;

  const QuizMenuWidget({super.key, required this.onSystemSelected, this.onClose});

  @override
  createState() => _QuizMenuWidgetState();
}

class _QuizMenuWidgetState extends State<QuizMenuWidget> {
  QuizMenuState _state = QuizMenuState.main;
  String? _selectedSubjectTitle;
  String? _selectedSubjectSlug;
  bool _isGoingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchCurrentQuote();
    });
  }

  void _showSmartReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartReviewSheet(
        onReviewSelected: (name, slug) {
          Navigator.pop(context); // Close sheet
          widget.onSystemSelected(name, slug); // Start quiz
        },
      ),
    );
  }

  final Map<String, String> _subjectSlugs = {
    'Pathophysiology': 'pathophysiology',
    'Pathology': 'pathology',
    'Microbiology': 'microbiology',
    'Pharmacology': 'pharmacology'
  };

  final List<String> _subjects = [
    'Pathophysiology',
    'Pathology',
    'Microbiology',
    'Pharmacology'
  ];

  void _onSubjectTap(String subject) {
    String slug = _subjectSlugs[subject] ?? subject.toLowerCase();
    
    // Trigger fetch from backend to get recency-sorted sections
    Provider.of<StatsProvider>(context, listen: false).fetchSubjectDetail(slug);

    setState(() {
      _isGoingBack = false;
      _selectedSubjectTitle = subject;
      _selectedSubjectSlug = slug;
      _state = QuizMenuState.systems;
    });
  }

  void _onBack() {
    setState(() {
      _isGoingBack = true;
      if (_state == QuizMenuState.systems) {
        _state = QuizMenuState.subjects;
        _selectedSubjectTitle = null;
        _selectedSubjectSlug = null;
      } else if (_state == QuizMenuState.subjects) {
        _state = QuizMenuState.main;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Unified Header
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_state != QuizMenuState.main)
                  GestureDetector(
                    onTap: _onBack,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 18, color: CozyTheme.of(context).textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _state == QuizMenuState.systems 
                              ? _getLocalizedSubjectTitle(_selectedSubjectTitle!) 
                              : AppLocalizations.of(context)!.quizSelectSubject,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
                        )
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 24),

                const SizedBox(width: 40), // Placeholder to keep spacing balanced if needed, or just remove
              ],
            ),
        ),

        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.fastOutSlowIn,
            switchOutCurve: Curves.easeInQuad,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final beginScale = _isGoingBack ? 1.08 : 0.92;
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: beginScale, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(_state),
              color: CozyTheme.of(context).paperCream,
              child: _buildCurrentContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentContent() {
    switch (_state) {
      case QuizMenuState.main:
        return _buildMainMenu();
      case QuizMenuState.subjects:
        return _buildList(_subjects, (item) => _onSubjectTap(item));
      case QuizMenuState.systems:
        return Consumer<StatsProvider>(
          builder: (context, stats, _) {
            final state = stats.getSectionState(_selectedSubjectSlug!);
            final List<Map<String, dynamic>> systems = stats.sectionMastery[_selectedSubjectSlug] ?? [];
            
            switch (state) {
              case SubjectQuizState.loading:
                final palette = CozyTheme.of(context);
                if (systems.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: palette.primary));
                }
                // If we have cached data, show it while loading (snappy UX)
                return _buildList(systems, (item) {
                  final name = _getLocalizedSectionName(context, item);
                  widget.onSystemSelected(name, item['slug']!);
                });
              case SubjectQuizState.initial:
              case SubjectQuizState.empty:
                final palette = CozyTheme.of(context);
                return Center(child: Text(AppLocalizations.of(context)!.quizComingSoon, style: TextStyle(color: palette.textSecondary)));
              case SubjectQuizState.error:
                final palette = CozyTheme.of(context);
                return Center(child: Text("Error fetching sections.", style: TextStyle(color: palette.error)));
              case SubjectQuizState.loaded:
                final palette = CozyTheme.of(context);
                if (systems.isEmpty) {
                   return Center(child: Text(AppLocalizations.of(context)!.quizComingSoon, style: TextStyle(color: palette.textSecondary)));
                }
                return _buildList(systems, (item) {
                  final name = _getLocalizedSectionName(context, item);
                  widget.onSystemSelected(name, item['slug']!);
                });
            }
          },
        );
    }
  }

  Widget _buildMainMenu() {
    return Padding(
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
              
              return _buildStudyBreakIcon(iconName, customUrl);
            },
          ),
          const SizedBox(height: 16), // Reduced from 24
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final locale = Localizations.localeOf(context).languageCode;
              final qc = stats.currentQuote;
              String displayTitle = AppLocalizations.of(context)!.quizStudyBreak;
              
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
                  color: CozyTheme.of(context).textPrimary
                )
              );
            }
          ),
          const SizedBox(height: 24), // Increased spacing
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final locale = Localizations.localeOf(context).languageCode;
              final quoteText = locale == 'hu' 
                  ? (stats.currentQuote?.textHu.isNotEmpty == true ? stats.currentQuote!.textHu : stats.currentQuote?.textEn)
                  : stats.currentQuote?.textEn;
              final displayQuote = quoteText ?? "Clear mind, focused goals.";
              final quoteAuthor = stats.currentQuote?.author ?? "MedBuddy";
              
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
                          fontStyle: FontStyle.italic
                        )
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
                          color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                  else
                    Text(
                      AppLocalizations.of(context)!.quizQuoteTopic,
                      style: GoogleFonts.inter(
                        fontSize: 16, 
                        color: CozyTheme.of(context).textSecondary,
                        height: 1.3
                      ),
                    ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),

          // --- SMART REVIEW CARD ---
          Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final readiness = stats.readiness?.overall ?? 0;
              return GestureDetector(
                onTap: _showSmartReview,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CozyTheme.of(context).primary.withValues(alpha: 0.1),
                        CozyTheme.of(context).primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CozyTheme.of(context).primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CozyTheme.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Smart Review",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CozyTheme.of(context).textPrimary,
                              ),
                            ),
                            Text(
                              "Readiness: $readiness%",
                              style: TextStyle(
                                fontSize: 14,
                                color: CozyTheme.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CozyTheme.of(context).primary),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const Spacer(),
          Row(
            children: [
              Expanded(child: _buildGridOption(AppLocalizations.of(context)!.quizSubjects, Icons.library_books_rounded, true, () {
                 setState(() {
                   _isGoingBack = false;
                   _state = QuizMenuState.subjects;
                 });
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildGridOption(AppLocalizations.of(context)!.quizECG, Icons.monitor_heart_rounded, true, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ECGPracticeScreen()));
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildGridOption("Cases", Icons.assignment_rounded, false, () {})), // Still disabled
            ],
          ),
          const SizedBox(height: 20), // Reduced from 30
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 setState(() {
                   _isGoingBack = false;
                   _state = QuizMenuState.subjects;
                 });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary,
                foregroundColor: CozyTheme.of(context).textInverse,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(AppLocalizations.of(context)!.quizStartSession, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CozyTheme.of(context).paperWhite)),
            ),
          ),
          const SizedBox(height: 10), // Reduced from 20
        ],
      ),
    );
  }

  Widget _buildGridOption(String title, IconData icon, bool isEnabled, VoidCallback onTap) {
    final palette = CozyTheme.of(context);
    final isActive = isEnabled;
    return GestureDetector(
       onTap: isActive ? onTap : null,
       child: Container(
         height: 90, // Reduced from 100
         decoration: BoxDecoration(
           color: isActive ? palette.paperWhite : palette.textSecondary.withValues(alpha: 0.05),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
             color: isActive ? palette.primary : palette.textSecondary.withValues(alpha: 0.2), 
             width: isActive ? 2 : 1
           ),
           boxShadow: isActive ? [BoxShadow(color: palette.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(icon, color: isActive ? palette.primary : palette.textSecondary.withValues(alpha: 0.4), size: 28), // Reduced size
             const SizedBox(height: 8),
             Text(title, style: TextStyle(
               color: isActive ? palette.textPrimary : palette.textSecondary,
               fontWeight: FontWeight.bold,
               fontSize: 12 // Reduced from 13
             )),
           ],
         ),
       ),
    );
  }

  Widget _buildList(dynamic items, Function(dynamic) onTap) {
    if (_state == QuizMenuState.subjects) {
       final List<String> listItems = List<String>.from(items);
       return Padding(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
         child: Column(
           children: [
             Expanded(
               child: Row(
                 children: [
                   Expanded(child: _buildSubjectCard(listItems[0], (s) => onTap(s))),
                   const SizedBox(width: 16),
                   Expanded(child: _buildSubjectCard(listItems[1], (s) => onTap(s))),
                 ],
               ),
             ),
             const SizedBox(height: 16),
             Expanded(
               child: Row(
                 children: [
                   Expanded(child: _buildSubjectCard(listItems[2], (s) => onTap(s))),
                   const SizedBox(width: 16),
                   Expanded(child: _buildSubjectCard(listItems[3], (s) => onTap(s))),
                 ],
               ),
             ),
             const SizedBox(height: 10),
           ],
         ),
       );
    }

    final List<Map<String, dynamic>> systemItems = List<Map<String, dynamic>>.from(items);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: systemItems.length,
      itemBuilder: (context, index) {
        final item = systemItems[index];
        int attempts = _parseSafeInt(item['attempts']);
        bool isRecent = index == 0 && attempts > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: CozyTile(
            onTap: () => onTap(item),
            isListTile: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedSectionName(context, item), 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (isRecent)
                        Text(
                          AppLocalizations.of(context)!.quizLastStudied, 
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: CozyTheme.of(context).primary, letterSpacing: 1)
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                FutureBuilder<bool>(
                  future: SyncService().isTopicOfflineReady(item['slug']),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Tooltip(
                        message: "Offline Ready",
                        child: Icon(Icons.check_circle_rounded, size: 16, color: CozyTheme.of(context).success),
                      );
                    }
                    return const SizedBox.shrink(); // Invisible if not ready (seamless)
                  },
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20, color: CozyTheme.of(context).primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(String subject, Function(String) onTap) {
    return CozyTile(
      onTap: () => onTap(subject),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSubjectColor(subject).withValues(alpha: 0.1),
              shape: BoxShape.circle
            ),
            child: Icon(_getSubjectIcon(subject), color: _getSubjectColor(subject), size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _getLocalizedSubjectTitle(subject), 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: CozyTheme.of(context).textPrimary,
              fontSize: 16
            )
          ),
        ],
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Pathophysiology': return Icons.healing_rounded;
      case 'Pathology': return Icons.biotech_rounded;
      case 'Microbiology': return Icons.coronavirus_rounded;
      case 'Pharmacology': return Icons.medication_rounded;
      default: return Icons.book_rounded;
    }
  }

  Color _getSubjectColor(String subject) {
    final palette = CozyTheme.of(context);
    switch (subject) {
      case 'Pathophysiology': return palette.error;
      case 'Pathology': return palette.secondary;
      case 'Microbiology': return palette.primary;
      case 'Pharmacology': return palette.warning;
      default: return palette.textSecondary;
    }
  }

  int _parseSafeInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _getLocalizedSectionName(BuildContext context, Map<String, dynamic> item) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'hu') {
      return (item['name_hu'] != null && item['name_hu'].toString().isNotEmpty)
          ? item['name_hu']
          : (item['name_en'] ?? item['section'] ?? '');
    }
    return item['name_en'] ?? item['section'] ?? '';
  }

  String _getLocalizedSubjectTitle(String englishTitle) {
    final l10n = AppLocalizations.of(context)!;
    switch (englishTitle) {
      case 'Pathophysiology': return l10n.quizSubjectPathophysiology;
      case 'Pathology': return l10n.quizSubjectPathology;
      case 'Microbiology': return l10n.quizSubjectMicrobiology;
      case 'Pharmacology': return l10n.quizSubjectPharmacology;
      default: return englishTitle;
    }
  }

  Widget _buildStudyBreakIcon(String iconName, String? customUrl) {
    bool showBackground = true;
    double scale = 1.0;
    String? checkUrl;

    if (customUrl == 'random_gallery' || iconName == 'random_gallery') {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      if (stats.uploadedIcons.isNotEmpty) {
        checkUrl = stats.uploadedIcons[Random().nextInt(stats.uploadedIcons.length)];
      } else {
        checkUrl = null;
      }
    } else if (customUrl != null && customUrl.isNotEmpty) {
      checkUrl = customUrl;
    } else if (iconName.startsWith('/') || iconName.startsWith('http')) {
      checkUrl = iconName;
    }

    if (checkUrl != null && checkUrl != 'random_gallery') {
      try {
        final uri = Uri.parse(checkUrl);
        if (uri.queryParameters.containsKey('bg')) {
          showBackground = uri.queryParameters['bg'] == 'true';
        }
        if (uri.queryParameters.containsKey('scale')) {
          scale = double.tryParse(uri.queryParameters['scale'] ?? '1.0') ?? 1.0;
        }
      } catch (_) {}
    }

    const double baseSize = 70.0;

    Widget mainIcon;
    if (checkUrl != null) {
      mainIcon = Image.network(
        '${ApiService.baseUrl}$checkUrl',
        width: baseSize * scale,
        height: baseSize * scale,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
      if (showBackground) {
        mainIcon = ClipOval(child: mainIcon);
      }
    } else {
      mainIcon = Icon(
        iconName == 'favorite_rounded' ? Icons.favorite_rounded : Icons.menu_book_rounded, 
        size: 50, 
        color: CozyTheme.of(context).primary
      );
    }

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: CozyTheme.of(context).primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: mainIcon,
      );
    } else {
      return SizedBox(
        width: 90,
        height: 90,
        child: Center(child: mainIcon),
      );
    }
  }
}
