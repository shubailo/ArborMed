import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../services/api_service.dart';
import '../../features/ecg/widgets/basic_interpretation_page.dart';
import '../../features/ecg/widgets/morphology_page.dart';
import '../../features/ecg/widgets/diagnosis_management_page.dart';
import '../../features/ecg/widgets/ecg_report_card.dart';

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

  bool get _hasHistory =>
      _currentCase?.findings['history']?.toString().trim().isNotEmpty == true;

  void _markInteracted(String section) {
    if (!_interactedSections.contains(section)) {
      setState(() => _interactedSections.add(section));
    }
  }

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
      _tWave,
    ];

    if (requiredFields.any((f) => f.isEmpty) ||
        _rateController.text.isEmpty ||
        _selectedDiagnosisId == null) {
      // Jump to the first page that has an error
      int targetPage = _hasHistory ? 1 : 0; // Skip history

      final bool hasPage1Error = [
            _rhythmRegularity,
            _conductionRatio,
            _prCategory,
            _qrsCategory,
            _qtCategory,
          ].any((f) => f.isEmpty) ||
          _rateController.text.isEmpty;

      final bool hasPage2Error = [
        _axis,
        _pWaveMorph,
        _atrialEnlargement,
        _hypertrophy,
        _bbb,
        _qWaves,
        _ischemia,
        _tWave,
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
        curve: Curves.easeOut,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Some fields are incomplete. Please review the highlighted sections.",
          ),
          backgroundColor: Colors.red,
        ),
      );
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
          ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''),
    );

    // Ensure standard is a valid Map
    final Map<String, dynamic> standard = _ensureMap(
      diagnosis.standardFindings,
    );

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
      String key,
      String title,
      dynamic userVal,
      dynamic standardVal,
    ) {
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
        'isCorrect': correct,
      };
    }

    // Helper for safe nested access
    dynamic getNested(Map map, String section, String key) {
      final s = map[section];
      if (s is Map) return s[key];
      return null;
    }

    addReportItem(
      'rhythm',
      'Rhythm',
      _rhythmRegularity,
      getNested(standard, 'rhythm', 'regularity'),
    );
    addReportItem(
      'sinus',
      'Sinus Rhythm',
      _isSinus ? 'Yes' : 'No',
      getNested(standard, 'rhythm', 'sinus') == true ? 'Yes' : 'No',
    );
    addReportItem(
      'rate',
      'Heart Rate',
      _rateController.text,
      getNested(standard, 'rate', 'max'),
    );

    // Grading logic for intervals
    addReportItem(
      'pr',
      'PR Interval',
      _prCategory,
      _mapMsToCategory(
        getNested(standard, 'conduction', 'pr_interval'),
        120,
        200,
      ),
    );
    addReportItem(
      'qrs',
      'QRS Duration',
      _qrsCategory,
      _mapMsToCategory(
        getNested(standard, 'conduction', 'qrs_duration'),
        0,
        120,
        isQrs: true,
      ),
    );
    addReportItem(
      'qt',
      'QT Interval',
      _qtCategory,
      _mapMsToCategory(
        getNested(standard, 'conduction', 'qt_interval'),
        0,
        440,
      ),
    );

    addReportItem(
      'av_block',
      'AV Block',
      _avBlock,
      getNested(standard, 'conduction', 'av_block') ?? 'None',
    );
    addReportItem(
      'sa_block',
      'SA Block',
      _saBlock,
      getNested(standard, 'rhythm', 'sa_block') ?? 'None',
    );
    addReportItem(
      'axis',
      'Heart Axis',
      _axis,
      getNested(standard, 'axis', 'quadrant'),
    );
    addReportItem(
      'pmorph',
      'P-Wave',
      _pWaveMorph,
      getNested(standard, 'p_wave', 'morphology'),
    );
    addReportItem(
      'atrial',
      'Atrial Enl.',
      _atrialEnlargement,
      getNested(standard, 'p_wave', 'atrial_enlargement'),
    );
    addReportItem(
      'hypertrophy',
      'Hypertrophy',
      _hypertrophy,
      getNested(standard, 'qrs_morph', 'hypertrophy'),
    );
    addReportItem(
      'bbb',
      'Bundle Branch',
      _bbb,
      getNested(standard, 'qrs_morph', 'bbb'),
    );
    addReportItem(
      'st',
      'ST Segment',
      _ischemia,
      getNested(standard, 'st_t', 'ischemia'),
    );
    addReportItem(
      'twave',
      'T-Wave',
      _tWave,
      getNested(standard, 'st_t', 't_wave'),
    );

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
        body: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }
    if (_currentCase == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "No ECG cases available.",
            style: TextStyle(color: palette.textPrimary),
          ),
        ),
      );
    }

    if (_showFeedback) {
      return ECGReportCard(
        feedbackReport: _feedbackReport,
        currentCase: _currentCase,
        interactedSections: _interactedSections,
        onNextCase: _loadNextCase,
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: palette.textPrimary),
          tooltip: 'Close challenge',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ECG Challenge",
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: palette.error, size: 16),
                const SizedBox(width: 4),
                StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                  builder: (ctx, snap) {
                    if (_startTime == null || _showFeedback) {
                      return Text(
                        "00:00",
                        style: TextStyle(
                          color: palette.error,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    final d = DateTime.now().difference(_startTime!);
                    final m = d.inMinutes.toString().padLeft(2, '0');
                    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
                    return Text(
                      "$m:$s",
                      style: TextStyle(
                        color: palette.error,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          decoration: BoxDecoration(
            color: palette.paperWhite,
            boxShadow: [
              BoxShadow(
                color: palette.textPrimary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                    child: Tooltip(
                      message: 'Tap to view full screen',
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
                                            color: palette.primary,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        Icons.fullscreen,
                        color: palette.textSecondary,
                        size: 28,
                      ),
                      tooltip: 'Full screen image',
                      onPressed: _showFullScreenImage,
                      style: IconButton.styleFrom(
                        backgroundColor: palette.surface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
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
                        physics:
                            const NeverScrollableScrollPhysics(), // Linear flow enforced
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        children: [
                          if (_hasHistory) _buildHistoryPage(palette),
                          BasicInterpretationPage(
                            rhythmRegularity: _rhythmRegularity,
                            isSinus: _isSinus,
                            conductionRatio: _conductionRatio,
                            rateController: _rateController,
                            prCategory: _prCategory,
                            qrsCategory: _qrsCategory,
                            qtCategory: _qtCategory,
                            avBlock: _avBlock,
                            saBlock: _saBlock,
                            triedSubmit: _triedSubmit,
                            onRhythmRegularityChanged: (v) =>
                                setState(() => _rhythmRegularity = v),
                            onIsSinusChanged: (v) =>
                                setState(() => _isSinus = v),
                            onConductionRatioChanged: (v) =>
                                setState(() => _conductionRatio = v),
                            onPrCategoryChanged: (v) =>
                                setState(() => _prCategory = v),
                            onQrsCategoryChanged: (v) =>
                                setState(() => _qrsCategory = v),
                            onQtCategoryChanged: (v) =>
                                setState(() => _qtCategory = v),
                            onAvBlockChanged: (v) =>
                                setState(() => _avBlock = v),
                            onSaBlockChanged: (v) =>
                                setState(() => _saBlock = v),
                            onInteracted: _markInteracted,
                          ),
                          MorphologyPage(
                            axis: _axis,
                            pWaveMorph: _pWaveMorph,
                            atrialEnlargement: _atrialEnlargement,
                            hypertrophy: _hypertrophy,
                            bbb: _bbb,
                            qWaves: _qWaves,
                            ischemia: _ischemia,
                            tWave: _tWave,
                            triedSubmit: _triedSubmit,
                            onAxisChanged: (v) => setState(() => _axis = v),
                            onPWaveMorphChanged: (v) =>
                                setState(() => _pWaveMorph = v),
                            onAtrialEnlargementChanged: (v) =>
                                setState(() => _atrialEnlargement = v),
                            onHypertrophyChanged: (v) =>
                                setState(() => _hypertrophy = v),
                            onBbbChanged: (v) => setState(() => _bbb = v),
                            onQWavesChanged: (v) => setState(() => _qWaves = v),
                            onIschemiaChanged: (v) =>
                                setState(() => _ischemia = v),
                            onTWaveChanged: (v) => setState(() => _tWave = v),
                            onInteracted: _markInteracted,
                          ),
                          DiagnosisManagementPage(
                            ecgCase: _currentCase!,
                            selectedDiagnosisId: _selectedDiagnosisId,
                            selectedSecondaryDiagnoses:
                                _selectedSecondaryDiagnoses,
                            urgency: _urgency,
                            managementNotesController:
                                _managementNotesController,
                            triedSubmit: _triedSubmit,
                            onDiagnosisSelected: (v) =>
                                setState(() => _selectedDiagnosisId = v),
                            onSecondaryDiagnosisAdded: (v) => setState(
                                () => _selectedSecondaryDiagnoses.add(v)),
                            onSecondaryDiagnosisRemoved: (v) => setState(
                                () => _selectedSecondaryDiagnoses.remove(v)),
                            onUrgencyChanged: (v) =>
                                setState(() => _urgency = v),
                          ),
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
        border: Border(
          bottom: BorderSide(
            color: palette.textSecondary.withValues(alpha: 0.05),
          ),
        ),
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
                  color: i < _currentPage
                      ? palette.primary
                      : palette.textSecondary.withValues(alpha: 0.1),
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
        color: isCurrent
            ? palette.primary
            : (isActive
                ? palette.primary.withValues(alpha: 0.2)
                : palette.surface),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? palette.primary
              : palette.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: isActive && !isCurrent
            ? Icon(Icons.check, size: 16, color: palette.primary)
            : Text(
                "${index + (_hasHistory ? 0 : 1)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      isCurrent ? palette.textInverse : palette.textSecondary,
                ),
              ),
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
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: palette.primary),
                ),
                child: Text(
                  "BACK",
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? "SUBMIT ANALYSIS" : "NEXT STEP",
                style: TextStyle(
                  color: palette.textInverse,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
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
              color: palette.textPrimary,
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
              child: Tooltip(
                message: 'Pan and zoom ECG',
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
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: palette.textInverse, size: 30),
                tooltip: 'Close full screen',
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
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Expanded(
          child: Divider(
            indent: 12,
            height: 24,
            color: palette.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ],
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
