import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../services/api_service.dart';

class ECGPracticeScreen extends StatefulWidget {
  const ECGPracticeScreen({super.key});

  @override
  State<ECGPracticeScreen> createState() => _ECGPracticeScreenState();
}

class _ECGPracticeScreenState extends State<ECGPracticeScreen> {
  ECGCase? _currentCase;
  bool _loading = true;
  DateTime? _startTime;

  // --- STATE VARIABLES (7+2 Steps) ---
  // 1. Rhythm
  String _rhythmRegularity = '';
  bool _isSinus = false;
  String _conductionRatio = '';

  // 2. Rate
  final TextEditingController _rateController = TextEditingController();

  // 3. Conduction
  String _prCategory = '';
  String _qrsCategory = '';
  String _qtCategory = '';
  String _avBlock = '';
  String _saBlock = '';

  // 4. Axis
  String _axis = '';

  // 5. P-Wave
  String _pWaveMorph = '';
  String _atrialEnlargement = '';

  // 6. QRS Morph
  String _hypertrophy = '';
  String _bbb = '';
  String _qWaves = '';

  // 7. ST-T Morph
  String _ischemia = '';
  String _tWave = '';

  // +1. Diagnosis
  int? _selectedDiagnosisId;
  final List<int> _selectedSecondaryDiagnoses = [];

  // +2. Management
  String _urgency = 'Routine';
  final TextEditingController _managementNotesController =
      TextEditingController();

  // Feedback State
  bool _showFeedback = false;
  Map<String, dynamic>? _feedbackReport;
  final Set<String> _interactedSections = {};
  bool _triedSubmit = false;
  
  // Wizard State
  late PageController _pageController;
  int _currentPage = 0;

  bool get _hasHistory => _currentCase?.findings['history']?.toString().trim().isNotEmpty == true;

  void _markInteracted(String section) {
    if (!_interactedSections.contains(section)) {
      setState(() => _interactedSections.add(section));
    }
  }

  // Static Options (Mirrors Admin)
  final List<String> regularityOpts = [
    'Regular',
    'Irregular',
    'Irregularly Irregular'
  ];
  final List<String> conductionOpts = [
    '1:1',
    '2:1',
    '3:1',
    'Variable',
    'Dissociated'
  ];
  final List<String> intervalOpts = ['Normal', 'Prolonged', 'Short'];
  final List<String> avBlocks = [
    'None',
    '1st Degree',
    '2nd Degree Type I',
    '2nd Degree Type II',
    '3rd Degree'
  ];
  final List<String> saBlocks = ['None', 'Sinus Arrest', 'SA Exit Block'];
  final List<String> axisList = [
    'Normal',
    'Left Deviation',
    'Right Deviation',
    'Extreme'
  ];
  final List<String> pMorphs = [
    'Normal',
    'Peaked',
    'Bifid',
    'Inverted',
    'Absent',
    'Sawtooth'
  ];
  final List<String> atrialSizes = [
    'None',
    'Left Atrial',
    'Right Atrial',
    'Bi-Atrial'
  ];
  final List<String> hypertrophyOpts = ['None', 'LVH', 'RVH', 'Bi-Ventricular'];
  final List<String> bbbOpts = ['None', 'LBBB', 'RBBB', 'IVCD'];
  final List<String> qWaveOpts = [
    'None',
    'Inferior',
    'Lateral',
    'Anterior',
    'Septal'
  ];
  final List<String> ischemiaOpts = [
    'None',
    'ST Elevation',
    'ST Depression',
    'Hyperacute T'
  ];
  final List<String> tWaveOpts = [
    'Normal',
    'Inverted',
    'Flattened',
    'Biphasic',
    'Peaked'
  ];
  final List<String> urgencyOpts = ['Routine', 'Urgent', 'Emergency'];

  @override
  void dispose() {
    _pageController.dispose();
    _rateController.dispose();
    _managementNotesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    if (stats.ecgCases.isEmpty) await stats.fetchECGCases();
    if (stats.ecgDiagnoses.isEmpty) await stats.fetchECGDiagnoses();

    if (mounted) {
      _loadNextCase();
    }
  }

  void _loadNextCase() {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _showFeedback = false;
      _feedbackReport = null;

      // Reset State
      _rhythmRegularity = '';
      _isSinus = false;
      _conductionRatio = '';
      _rateController.clear();
      _prCategory = '';
      _qrsCategory = '';
      _qtCategory = '';
      _avBlock = '';
      _saBlock = '';
      _axis = '';
      _pWaveMorph = '';
      _atrialEnlargement = '';
      _hypertrophy = '';
      _bbb = '';
      _qWaves = '';
      _ischemia = '';
      _tWave = '';
      _selectedDiagnosisId = null;
      _selectedSecondaryDiagnoses.clear();
      _urgency = 'Routine';
      _managementNotesController.clear();
      _interactedSections.clear();
      _triedSubmit = false;

      if (stats.ecgCases.isNotEmpty) {
        _currentCase = (stats.ecgCases..shuffle()).first;
        _startTime = DateTime.now();
      }
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _loading = false;
    });
  }

  void _submit() {
    setState(() => _triedSubmit = true);

    // Validation Check: Ensure all dropdowns (non-optional ones) are filled
    final requiredFields = [
      _rhythmRegularity,
      _conductionRatio,
      _prCategory,
      _qrsCategory,
      _qtCategory,
      _axis,
      _pWaveMorph,
      _atrialEnlargement,
      _hypertrophy,
      _bbb,
      _qWaves,
      _ischemia,
      _tWave
    ];

    if (requiredFields.any((f) => f.isEmpty) ||
        _rateController.text.isEmpty ||
        _selectedDiagnosisId == null) {
      
      // Jump to the first page that has an error
      int targetPage = _hasHistory ? 1 : 0; // Skip history
      
      final bool hasPage1Error = [
        _rhythmRegularity, _conductionRatio, _prCategory, _qrsCategory, _qtCategory
      ].any((f) => f.isEmpty) || _rateController.text.isEmpty;
      
      final bool hasPage2Error = [
        _axis, _pWaveMorph, _atrialEnlargement, _hypertrophy, _bbb, _qWaves, _ischemia, _tWave
      ].any((f) => f.isEmpty);

      if (hasPage1Error) {
        targetPage = _hasHistory ? 1 : 0;
      } else if (hasPage2Error) {
        targetPage = _hasHistory ? 2 : 1;
      } else {
        targetPage = _hasHistory ? 3 : 2;
      }

      _pageController.animateToPage(
        targetPage, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeOut
      );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text("Some fields are incomplete. Please review the highlighted sections."),
      backgroundColor: Colors.red,
    ));
    return;
  }

    // Calculate duration
    final startTime = _startTime ?? DateTime.now();
    final duration = DateTime.now().difference(startTime);

    // Get standard findings from the master diagnosis list
    final stats = Provider.of<StatsProvider>(context, listen: false);
    
    // Safety check for current case
    if (_currentCase == null) return;

    final diagnosis = stats.ecgDiagnoses.firstWhere(
        (d) => d.id == _currentCase!.diagnosisId,
        orElse: () =>
            ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''));
    
    // Ensure standard is a valid Map
    final Map<String, dynamic> standard = _ensureMap(diagnosis.standardFindings);

    // Grading Logic
    // 1. Diagnosis Check
    bool isDxCorrect = _selectedDiagnosisId == _currentCase!.diagnosisId;

    // 2. Score Calculation
    int score = 0;
    int interpretationCount = _interactedSections.length;
    bool isLazy = interpretationCount < 4; // Threshold for penalty

    if (isDxCorrect) {
      // Base points for accuracy
      if (duration.inSeconds < 60) {
        score = 5;
      } else if (duration.inSeconds < 120) {
        score = 4;
      } else if (duration.inSeconds < 300) {
        score = 3;
      } else {
        score = 2;
      }

      // Penalty for skipping steps
      if (isLazy && score > 2) {
        score = 2; // Cap at 2 stars if they skipped most steps
      }
      if (interpretationCount == 0 && score > 1) {
        score = 1; // Minimum points if they literal just clicked diagnosis
      }
    } else {
      score = 1; // Participation
    }
    // 3. Secondary Diagnosis Check
    bool secondaryDxCorrect = true;
    if (_currentCase!.secondaryDiagnosesIds.isNotEmpty) {
      // Basic check: did they find all required secondary diagnoses?
      final expectedSet = _currentCase!.secondaryDiagnosesIds.toSet();
      final selectedSet = _selectedSecondaryDiagnoses.toSet();
      secondaryDxCorrect = expectedSet.difference(selectedSet).isEmpty &&
          selectedSet.difference(expectedSet).isEmpty;
    }

    // Detailed Comparison for Report Card
    final reportData = <String, Map<String, dynamic>>{};

    void addReportItem(
        String key, String title, dynamic userVal, dynamic standardVal) {
      bool correct = false;
      if (key == 'rate' && userVal != null && standardVal != null) {
        final u = int.tryParse(userVal.toString());
        final s = int.tryParse(standardVal.toString());
        if (u != null && s != null) {
          correct = (u - s).abs() <= 5; // +/- 5 BPM Grace Zone
        }
      } else {
        correct = userVal?.toString().toLowerCase() ==
            standardVal?.toString().toLowerCase();
      }

      reportData[key] = {
        'title': title,
        'user': userVal?.toString() ?? 'N/A',
        'standard': standardVal?.toString() ?? 'N/A',
        'isCorrect': correct
      };
    }

    // Helper for safe nested access
    dynamic getNested(Map map, String section, String key) {
      final s = map[section];
      if (s is Map) return s[key];
      return null;
    }

    addReportItem('rhythm', 'Rhythm', _rhythmRegularity,
        getNested(standard, 'rhythm', 'regularity'));
    addReportItem('sinus', 'Sinus Rhythm', _isSinus ? 'Yes' : 'No',
        getNested(standard, 'rhythm', 'sinus') == true ? 'Yes' : 'No');
    addReportItem(
        'rate', 'Heart Rate', _rateController.text, getNested(standard, 'rate', 'max'));

    // Grading logic for intervals
    addReportItem('pr', 'PR Interval', _prCategory,
        _mapMsToCategory(getNested(standard, 'conduction', 'pr_interval'), 120, 200));
    addReportItem(
        'qrs',
        'QRS Duration',
        _qrsCategory,
        _mapMsToCategory(getNested(standard, 'conduction', 'qrs_duration'), 0, 120,
            isQrs: true));
    addReportItem('qt', 'QT Interval', _qtCategory,
        _mapMsToCategory(getNested(standard, 'conduction', 'qt_interval'), 0, 440));

    addReportItem('av_block', 'AV Block', _avBlock,
        getNested(standard, 'conduction', 'av_block') ?? 'None');
    addReportItem('sa_block', 'SA Block', _saBlock,
        getNested(standard, 'rhythm', 'sa_block') ?? 'None');
    addReportItem('axis', 'Heart Axis', _axis, getNested(standard, 'axis', 'quadrant'));
    addReportItem(
        'pmorph', 'P-Wave', _pWaveMorph, getNested(standard, 'p_wave', 'morphology'));
    addReportItem('atrial', 'Atrial Enl.', _atrialEnlargement,
        getNested(standard, 'p_wave', 'atrial_enlargement'));
    addReportItem('hypertrophy', 'Hypertrophy', _hypertrophy,
        getNested(standard, 'qrs_morph', 'hypertrophy'));
    addReportItem('bbb', 'Bundle Branch', _bbb, getNested(standard, 'qrs_morph', 'bbb'));
    addReportItem('st', 'ST Segment', _ischemia, getNested(standard, 'st_t', 'ischemia'));
    addReportItem('twave', 'T-Wave', _tWave, getNested(standard, 'st_t', 't_wave'));

    setState(() {
      _showFeedback = true;
      _feedbackReport = {
        'score': score,
        'time': duration.inSeconds,
        'isCorrect': isDxCorrect && secondaryDxCorrect,
        'correctDiagnosisId': _currentCase!.diagnosisId,
        'secondaryDxCorrect': secondaryDxCorrect,
        'detailed': reportData,
        'primary_dx_correct': isDxCorrect,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    if (_loading) {
      return Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: palette.primary)));
    }
    if (_currentCase == null) {
      return Scaffold(
          body: Center(
              child: Text("No ECG cases available.",
                  style: TextStyle(color: palette.textPrimary))));
    }

    if (_showFeedback) return _buildReportCard(); // Full screen exit early

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("ECG Challenge",
            style: TextStyle(
                color: palette.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.favorite, color: palette.error, size: 16),
                const SizedBox(width: 4),
                StreamBuilder<int>(
                    stream:
                        Stream.periodic(const Duration(seconds: 1), (i) => i),
                    builder: (ctx, snap) {
                      if (_startTime == null || _showFeedback) {
                        return Text("00:00",
                            style: TextStyle(
                                color: palette.error,
                                fontWeight: FontWeight.bold));
                      }
                      final d = DateTime.now().difference(_startTime!);
                      final m = d.inMinutes.toString().padLeft(2, '0');
                      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
                      return Text("$m:$s",
                          style: TextStyle(
                              color: palette.error,
                              fontWeight: FontWeight.bold));
                    })
              ]))
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          decoration: BoxDecoration(color: palette.paperWhite, boxShadow: [
            BoxShadow(
              color: palette.textPrimary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ]),
          child: Column(
            children: [
              // 1. Zoomable Image (Restrained height and side padding for desktop)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    color: palette.paperWhite,
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 6.0,
                        child: Image.network(
                          _currentCase!.imageUrl.startsWith('http')
                              ? _currentCase!.imageUrl
                              : '${ApiService.baseUrl}${_currentCase!.imageUrl}',
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : SizedBox(
                                      height: 200,
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: palette.primary))),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: Icon(Icons.fullscreen,
                            color: palette.textSecondary, size: 28),
                        onPressed: _showFullScreenImage,
                        style: IconButton.styleFrom(
                            backgroundColor:
                                palette.surface.withValues(alpha: 0.7)),
                      ))
                ],
              ),

              // 2. Wizard Pages (Dynamic Content)
              Expanded(
                child: Column(
                  children: [
                    // Progress Indicator
                    _buildWizardProgress(),
                    
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(), // Linear flow enforced
                        onPageChanged: (idx) => setState(() => _currentPage = idx),
                        children: [
                          if (_hasHistory) _buildHistoryPage(palette),
                          _buildBasicInterpretationPage(palette),
                          _buildMorphologyPage(palette),
                          _buildDiagnosisManagementPage(palette),
                        ],
                      ),
                    ),
                    
                    // Navigation Bar
                    _buildWizardNavigation(palette),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardProgress() {
    final palette = CozyTheme.of(context);
    final totalPages = (_hasHistory ? 1 : 0) + 3;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: palette.textSecondary.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < totalPages; i++) ...[
            // Step circle
            _buildStepCircle(i, palette),
            // Connector line
            if (i < totalPages - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i < _currentPage ? palette.primary : palette.textSecondary.withValues(alpha: 0.1),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, CozyPalette palette) {
    final isActive = index <= _currentPage;
    final isCurrent = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrent ? palette.primary : (isActive ? palette.primary.withValues(alpha: 0.2) : palette.surface),
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? palette.primary : palette.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: isActive && !isCurrent
          ? Icon(Icons.check, size: 16, color: palette.primary)
          : Text("${index + (_hasHistory ? 0 : 1)}", 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isCurrent ? palette.textInverse : palette.textSecondary
              )),
      ),
    );
  }


  Widget _buildWizardNavigation(CozyPalette palette) {
    final totalPages = (_hasHistory ? 1 : 0) + 3;
    final isLastPage = _currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        boxShadow: [
          BoxShadow(
            color: palette.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: palette.primary),
                ),
                child: Text("BACK", style: TextStyle(color: palette.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLastPage) {
                  _submit();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? "SUBMIT ANALYSIS" : "NEXT STEP",
                style: TextStyle(
                  color: palette.textInverse, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(CozyPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader("Patient History", Icons.history_edu),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.primary.withValues(alpha: 0.1)),
          ),
          child: Text(
            _currentCase!.findings['history']?.toString() ?? "",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: palette.textPrimary
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Review the history and the ECG above carefully before proceeding to the technical interpretation.",
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBasicInterpretationPage(CozyPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader("1. Rhythm", Icons.show_chart),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _buildDropdown(
                  "Regularity", _rhythmRegularity, regularityOpts,
                  (v) {
            _rhythmRegularity = v;
            _markInteracted("rhythm");
          })),
          const SizedBox(width: 12),
          Expanded(
              child: CheckboxListTile(
            title: const Text("Sinus Rhythm?",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text("P before QRS",
                style: TextStyle(
                    fontSize: 11, color: palette.textSecondary)),
            value: _isSinus,
            onChanged: (v) {
              setState(() => _isSinus = v!);
              _markInteracted("rhythm");
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          )),
        ]),
        const SizedBox(height: 12),
        _buildDropdown("Conduction (e.g. 1:1)", _conductionRatio,
            conductionOpts, (v) {
          _conductionRatio = v;
          _markInteracted("rhythm");
        }),
        const SizedBox(height: 32),

        _buildSectionHeader("2. Rate", Icons.timer),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          decoration: CozyTheme.inputDecoration(
                  context, "Heart Rate (BPM)")
              .copyWith(
                  prefixIcon: const Icon(Icons.favorite_border)),
          onChanged: (_) => _markInteracted("rate"),
        ),
        const SizedBox(height: 32),

        _buildSectionHeader("3. Conduction", Icons.speed),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _buildDropdown(
                  "PR Interval", _prCategory, intervalOpts, (v) {
            _prCategory = v;
            _markInteracted("conduction");
          })),
          const SizedBox(width: 8),
          Expanded(
              child: _buildDropdown(
                  "QRS Width", _qrsCategory, intervalOpts, (v) {
            _qrsCategory = v;
            _markInteracted("conduction");
          })),
          const SizedBox(width: 8),
          Expanded(
              child: _buildDropdown(
                  "QT Interval", _qtCategory, intervalOpts, (v) {
            _qtCategory = v;
            _markInteracted("conduction");
          })),
        ]),
        const SizedBox(height: 12),
        if (_prCategory == 'Prolonged') ...[
          _buildDropdown("AV Block", _avBlock, avBlocks, (v) {
            _avBlock = v;
            _markInteracted("conduction");
          }),
          const SizedBox(height: 12),
        ],
        _buildDropdown("SA Block", _saBlock, saBlocks, (v) {
          _saBlock = v;
          _markInteracted("conduction");
        }),
      ],
    );
  }

  Widget _buildMorphologyPage(CozyPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader("4. Axis", Icons.explore),
        const SizedBox(height: 16),
        _buildDropdown("Heart Axis", _axis, axisList, (v) {
          _axis = v;
          _markInteracted("axis");
        }),
        const SizedBox(height: 32),

        _buildSectionHeader("5/6/7. Morphology", Icons.graphic_eq),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _buildDropdown(
                  "P-Wave", _pWaveMorph, pMorphs, (v) {
            _pWaveMorph = v;
            _markInteracted("morphology");
          })),
          const SizedBox(width: 12),
          Expanded(
              child: _buildDropdown("Atrial Enlargement",
                  _atrialEnlargement, atrialSizes, (v) {
            _atrialEnlargement = v;
            _markInteracted("morphology");
          })),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _buildDropdown("QRS Hypertrophy",
                  _hypertrophy, hypertrophyOpts, (v) {
            _hypertrophy = v;
            _markInteracted("morphology");
          })),
          const SizedBox(width: 12),
          Expanded(
              child: _buildDropdown(
                  "Bundle Branch Block", _bbb, bbbOpts, (v) {
            _bbb = v;
            _markInteracted("morphology");
          })),
        ]),
        const SizedBox(height: 12),
        _buildDropdown("Pathological Q-Waves", _qWaves, qWaveOpts,
            (v) {
          _qWaves = v;
          _markInteracted("morphology");
        }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _buildDropdown(
                  "ST Ischemia", _ischemia, ischemiaOpts, (v) {
            _ischemia = v;
            _markInteracted("morphology");
          })),
          const SizedBox(width: 12),
          Expanded(
              child: _buildDropdown("T-Wave", _tWave, tWaveOpts,
                  (v) {
            _tWave = v;
            _markInteracted("morphology");
          })),
        ]),
      ],
    );
  }

  Widget _buildDiagnosisManagementPage(CozyPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader("Final Diagnosis", Icons.check_circle_outline),
        const SizedBox(height: 16),
        _buildDiagnosisSearch(),
        if (_currentCase!.secondaryDiagnosesIds.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSecondaryDiagnosisSearch(),
        ],
        const SizedBox(height: 32),

        if (_currentCase!.findings['management'] != null) ...[
          _buildSectionHeader("8. Management", Icons.medical_services),
          const SizedBox(height: 16),
          _buildDropdown("Urgency Level", _urgency, urgencyOpts,
              (v) => _urgency = v),
          const SizedBox(height: 16),
          TextFormField(
            controller: _managementNotesController,
            maxLines: 3,
            decoration: CozyTheme.inputDecoration(
                    context, "Management Notes")
                .copyWith(
                    hintText: "Describe next steps / management..."),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: palette.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Double check your interpretation before submitting.",
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _showFullScreenImage() {
    final palette = CozyTheme.of(context, listen: false);
    final imageUrl = _currentCase!.imageUrl.startsWith('http')
        ? _currentCase!.imageUrl
        : '${ApiService.baseUrl}${_currentCase!.imageUrl}';
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: palette.textPrimary.withValues(alpha: 0.9),
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: palette.textInverse, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    final palette = CozyTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: palette.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary)),
        Expanded(
            child: Divider(
                indent: 12,
                height: 24,
                color: palette.textSecondary.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String) onChanged) {
    final palette = CozyTheme.of(context);
    bool hasError = _triedSubmit && value.isEmpty;

    return InputDecorator(
      decoration: CozyTheme.inputDecoration(context, label).copyWith(
        labelStyle: TextStyle(color: hasError ? palette.error : null),
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.error, width: 2))
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            isExpanded: true,
            hint: Text("Select $label...",
                style: TextStyle(
                    fontSize: 14,
                    color: hasError
                        ? palette.error.withValues(alpha: 0.5)
                        : palette.textSecondary)),
            items: items
                .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => onChanged(val!)),
          ),
        ),
      );
  }

  Widget _buildSecondaryDiagnosisSearch() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Secondary Diagnoses",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: CozyTheme.of(context).textSecondary)),
            const SizedBox(height: 8),
            Autocomplete<ECGDiagnosis>(
              displayStringForOption: (d) => "${d.code} - ${d.nameEn}",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<ECGDiagnosis>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return stats.ecgDiagnoses.where((d) =>
                    d.id != _selectedDiagnosisId &&
                    !_selectedSecondaryDiagnoses.contains(d.id) &&
                    (d.nameEn.toLowerCase().contains(query) ||
                        d.code.toLowerCase().contains(query)));
              },
              onSelected: (ECGDiagnosis selection) {
                setState(() => _selectedSecondaryDiagnoses.add(selection.id));
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: CozyTheme.inputDecoration(
                          context, "Add Secondary Diagnosis")
                      .copyWith(
                    prefixIcon: Icon(Icons.add_circle_outline,
                        color: CozyTheme.of(context).textSecondary),
                  ),
                );
              },
            ),
            if (_selectedSecondaryDiagnoses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSecondaryDiagnoses.map((id) {
                  final d = stats.ecgDiagnoses.firstWhere((e) => e.id == id,
                      orElse: () => ECGDiagnosis(
                          id: id, code: '?', nameEn: 'Unknown', nameHu: ''));
                  return Chip(
                    label: Text(d.code, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        setState(() => _selectedSecondaryDiagnoses.remove(id)),
                    backgroundColor:
                        CozyTheme.of(context).primary.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: CozyTheme.of(context)
                            .primary
                            .withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDiagnosisSearch() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        return Autocomplete<ECGDiagnosis>(
            displayStringForOption: (d) => "${d.code} - ${d.nameEn}",
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<ECGDiagnosis>.empty();
              }
              final query = textEditingValue.text.toLowerCase();
              return stats.ecgDiagnoses.where((d) =>
                  d.nameEn.toLowerCase().contains(query) ||
                  d.nameHu.toLowerCase().contains(query) ||
                  d.code.toLowerCase().contains(query));
            },
            onSelected: (ECGDiagnosis selection) {
              setState(() => _selectedDiagnosisId = selection.id);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration:
                    CozyTheme.inputDecoration(context, "Primary Diagnosis")
                        .copyWith(
                            prefixIcon: Icon(Icons.search,
                                color: CozyTheme.of(context).textSecondary),
                            fillColor: CozyTheme.of(context)
                                .primary
                                .withValues(alpha: 0.05),
                            filled: true),
              );
            });
      },
    );
  }

  Widget _buildReportCard() {
    final feedback = _feedbackReport ?? {};
    final isCorrect = feedback['isCorrect'] == true;
    final score = int.tryParse(feedback['score']?.toString() ?? '1') ?? 1;
    final time = int.tryParse(feedback['time']?.toString() ?? '0') ?? 0;
    final correctDxId = int.tryParse(feedback['correctDiagnosisId']?.toString() ?? '0') ?? 0;
    final primaryCorrect = feedback['primary_dx_correct'] == true;
    final Map<String, dynamic> detailed = _ensureMap(feedback['detailed']);

    final stats = Provider.of<StatsProvider>(context, listen: false);
    final diagnosis = stats.ecgDiagnoses.firstWhere((d) => d.id == correctDxId,
        orElse: () =>
            ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''));

    final palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Case Review",
            style: TextStyle(
                color: palette.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Score Header
          Center(
            child: Column(
              children: [
                Icon(isCorrect ? Icons.emoji_events : Icons.assignment_late,
                    size: 80,
                    color: isCorrect ? palette.warning : palette.secondary),
                const SizedBox(height: 16),
                Text(isCorrect ? "Excellent Interpretation!" : "Keep Learning",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary)),
                const SizedBox(height: 4),
                Text("Time spent: ${time}s",
                    style: TextStyle(color: palette.textSecondary)),
                const SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        5,
                        (i) => Icon(Icons.star,
                            color: i < score
                                ? palette.warning
                                : palette.textSecondary.withValues(alpha: 0.2),
                            size: 32))),
                if (_interactedSections.length < 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Score capped: Interpretation steps skipped.",
                        style: TextStyle(
                            color: palette.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Main Diagnosis Result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: primaryCorrect
                    ? palette.success.withValues(alpha: 0.1)
                    : palette.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: primaryCorrect
                        ? palette.success.withValues(alpha: 0.3)
                        : palette.error.withValues(alpha: 0.3))),
            child: Column(children: [
              Text(
                  primaryCorrect
                      ? "Correct Primary Diagnosis"
                      : "Incorrect Primary Diagnosis",
                  style: TextStyle(
                      fontSize: 12,
                      color: primaryCorrect ? palette.success : palette.error,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${diagnosis.code} - ${diagnosis.nameEn}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary),
                  textAlign: TextAlign.center),
              if (!primaryCorrect)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("You suggested a different diagnosis.",
                      style: TextStyle(color: palette.error, fontSize: 13)),
                )
            ]),
          ),

          const SizedBox(height: 32),

          // Detailed Comparison Table
          Text("Step-by-Step Analysis",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: palette.textSecondary.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text("Interpretation Step",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: palette.textSecondary))),
                    Expanded(
                        flex: 2,
                        child: Text("Your Input",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: palette.textSecondary))),
                    Expanded(
                        flex: 2,
                        child: Text("Expert Findings",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: palette.textSecondary))),
                  ]),
                ),
                const Divider(height: 1),
                // Comparison Rows
                ...detailed.entries.map((e) {
                  final data = e.value;
                  if (data is! Map) return const SizedBox.shrink();
                  
                  final isMatch = data['isCorrect'] == true;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Text(data['title']?.toString() ?? 'Unknown',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary))),
                          Expanded(
                              flex: 2,
                              child: Text(data['user']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isMatch
                                          ? palette.success
                                          : palette.error))),
                          Expanded(
                              flex: 2,
                              child: Text(data['standard']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: palette.textSecondary,
                                      fontWeight: FontWeight.bold))),
                        ]),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Secondary Diagnoses Comparison
          if (_currentCase!.secondaryDiagnosesIds.isNotEmpty) ...[
            Text("Secondary Findings",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gold Standard Secondary Diagnoses:",
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _currentCase!.secondaryDiagnosesIds.map((id) {
                      final d = stats.ecgDiagnoses.firstWhere((e) => e.id == id,
                          orElse: () => ECGDiagnosis(
                              id: id,
                              code: '?',
                              nameEn: 'Unknown',
                              nameHu: ''));
                      return Chip(
                        label: Text(d.code),
                        backgroundColor: palette.paperWhite,
                        side: BorderSide(
                            color:
                                palette.textSecondary.withValues(alpha: 0.1)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Management (If correct)
          if (isCorrect && _currentCase?.findings != null && _currentCase!.findings['management'] != null) ...[
            Builder(builder: (context) {
              final management = _currentCase!.findings['management'];
              if (management is! Map) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Clinical Management",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: palette.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: palette.warning.withValues(alpha: 0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.emergency, color: palette.warning, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              "Urgency: ${management['urgency'] ?? 'Routine'}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            management['notes']?.toString() ??
                                "No management notes provided.",
                            style:
                                TextStyle(fontSize: 14, color: palette.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            }),
          ],

          ElevatedButton(
            onPressed: _loadNextCase,
            style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Text("CLOSE & START NEXT CASE",
                style: TextStyle(
                    color: palette.textInverse,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _mapMsToCategory(dynamic val, int min, int max, {bool isQrs = false}) {
    if (val == null) return 'Normal';
    final n = int.tryParse(val.toString()) ?? 0;
    if (n == 0) return 'Normal';

    // Logic: PR > 200 = Prolonged, QRS > 120 = Prolonged, QT > 440 = Prolonged
    if (n > max) return 'Prolonged';
    if (min > 0 && n < min) return 'Short';
    return 'Normal';
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
