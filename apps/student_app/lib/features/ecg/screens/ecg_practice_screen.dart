import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analytics/models/ecg_case.dart';
import '../../../features/analytics/models/ecg_diagnosis.dart';
import '../../../services/admin_question_provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/cozy_theme.dart';
import '../services/ecg_grading_service.dart';
import '../widgets/basic_interpretation_page.dart';
import '../widgets/diagnosis_management_page.dart';
import '../widgets/ecg_image_viewer.dart';
import '../widgets/ecg_report_card.dart';
import '../widgets/ecg_wizard_nav.dart';
import '../widgets/morphology_page.dart';

/// Interactive ECG clinical practice challenge screen.
class ECGPracticeScreen extends StatefulWidget {
  const ECGPracticeScreen({super.key});

  @override
  State<ECGPracticeScreen> createState() => _ECGPracticeScreenState();
}

class _ECGPracticeScreenState extends State<ECGPracticeScreen> {
  ECGCase? _currentCase;
  bool _loading = true;
  DateTime? _startTime;

  // 1. Rhythm & Rate State
  String _rhythmRegularity = '';
  bool _isSinus = false;
  String _conductionRatio = '';
  final TextEditingController _rateController = TextEditingController();

  // 2. Conduction Intervals & Blocks
  String _prCategory = '';
  String _qrsCategory = '';
  String _qtCategory = '';
  String _avBlock = '';
  String _saBlock = '';

  // 3. Axis & Morphology
  String _axis = '';
  String _pWaveMorph = '';
  String _atrialEnlargement = '';
  String _hypertrophy = '';
  String _bbb = '';
  String _qWaves = '';
  String _ischemia = '';
  String _tWave = '';

  // 4. Clinical Diagnosis & Management
  int? _selectedDiagnosisId;
  final List<int> _selectedSecondaryDiagnoses = [];
  String _urgency = 'Routine';
  final TextEditingController _managementNotesController =
      TextEditingController();

  // Session Flow & Feedback State
  bool _showFeedback = false;
  Map<String, dynamic>? _feedbackReport;
  final Set<String> _interactedSections = {};
  bool _triedSubmit = false;
  bool _submitting = false;

  late PageController _pageController;
  int _currentPage = 0;

  bool get _hasHistory =>
      _currentCase?.findings['history']?.toString().trim().isNotEmpty == true;

  int get _totalPages => (_hasHistory ? 1 : 0) + 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rateController.dispose();
    _managementNotesController.dispose();
    super.dispose();
  }

  void _markInteracted(String section) {
    if (!_interactedSections.contains(section)) {
      setState(() => _interactedSections.add(section));
    }
  }

  Future<void> _loadData() async {
    final stats = Provider.of<AdminQuestionProvider>(context, listen: false);
    if (stats.ecgCases.isEmpty) await stats.fetchECGCases();
    if (stats.ecgDiagnoses.isEmpty) await stats.fetchECGDiagnoses();

    if (mounted) {
      _loadNextCase();
    }
  }

  void _loadNextCase() {
    final stats = Provider.of<AdminQuestionProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _showFeedback = false;
      _feedbackReport = null;

      // Reset values
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

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _triedSubmit = true);

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

    final bool hasEmptyRequired = requiredFields.any((f) => f.isEmpty) ||
        _rateController.text.trim().isEmpty ||
        _selectedDiagnosisId == null;

    if (hasEmptyRequired) {
      _navigateToFirstIncompletePage();
      return;
    }

    if (_currentCase == null) return;

    final stats = Provider.of<AdminQuestionProvider>(context, listen: false);
    final submission = EcgSubmission(
      rhythmRegularity: _rhythmRegularity,
      isSinus: _isSinus,
      conductionRatio: _conductionRatio,
      rate: _rateController.text.trim(),
      prCategory: _prCategory,
      qrsCategory: _qrsCategory,
      qtCategory: _qtCategory,
      avBlock: _avBlock,
      saBlock: _saBlock,
      axis: _axis,
      pWaveMorph: _pWaveMorph,
      atrialEnlargement: _atrialEnlargement,
      hypertrophy: _hypertrophy,
      bbb: _bbb,
      qWaves: _qWaves,
      ischemia: _ischemia,
      tWave: _tWave,
      selectedDiagnosisId: _selectedDiagnosisId,
      selectedSecondaryDiagnoses:
          List.unmodifiable(_selectedSecondaryDiagnoses),
      urgency: _urgency,
      managementNotes: _managementNotesController.text.trim(),
    );

    final duration = DateTime.now().difference(_startTime ?? DateTime.now());

    setState(() => _submitting = true);
    try {
      final feedback = await ApiService()
          .post('/ecg/cases/${_currentCase!.id}/interpretations', {
        'diagnosisId': submission.selectedDiagnosisId,
        'secondaryDiagnosisIds': submission.selectedSecondaryDiagnoses,
      });
      if (!mounted) return;
      final reviewCase = ECGCase.fromJson(feedback['case']);
      final fallbackDiagnosis = stats.ecgDiagnoses.firstWhere(
        (d) => d.id == reviewCase.diagnosisId,
        orElse: () =>
            ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''),
      );

      final result = EcgGradingService.grade(
        submission: submission,
        ecgCase: reviewCase,
        duration: duration,
        interactedSections: _interactedSections,
        fallbackMasterFindings: fallbackDiagnosis.standardFindings,
      );

      setState(() {
        _showFeedback = true;
        _currentCase = reviewCase;
        _feedbackReport = {
          ...result.toMap(),
          'primary_dx_correct': feedback['primaryCorrect'],
          'secondaryDxCorrect': feedback['secondaryCorrect'],
          'isCorrect': feedback['primaryCorrect'] == true &&
              feedback['secondaryCorrect'] == true,
        };
      });
    } catch (_) {
      if (mounted) {
        final hu = Localizations.localeOf(context).languageCode == 'hu';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(hu
                ? 'Az értékelés nem érhető el. Próbáld újra.'
                : 'Grading is unavailable. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _navigateToFirstIncompletePage() {
    final bool hasPage1Error = [
          _rhythmRegularity,
          _conductionRatio,
          _prCategory,
          _qrsCategory,
          _qtCategory,
        ].any((f) => f.isEmpty) ||
        _rateController.text.trim().isEmpty;

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

    int targetPage = _hasHistory ? 1 : 0;
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

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHu
              ? 'Néhány mező kitöltetlen. Kérjük, tekintse át a megjelölt részeket.'
              : 'Some fields are incomplete. Please review the highlighted sections.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }

    if (_currentCase == null) {
      return Scaffold(
        body: Center(
          child: Text(
            isHu ? "Nincsenek elérhető EKG esetek." : "No ECG cases available.",
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
      appBar: _buildAppBar(palette, isHu),
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
              EcgImageViewer(imageUrl: _currentCase!.imageUrl),
              Expanded(
                child: Column(
                  children: [
                    EcgWizardProgress(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      hasHistory: _hasHistory,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        children: [
                          if (_hasHistory) _buildHistoryPage(palette, isHu),
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
                    EcgWizardNavigation(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      onNext: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      onSubmit: _submit,
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

  PreferredSizeWidget _buildAppBar(CozyPalette palette, bool isHu) {
    return AppBar(
      backgroundColor: palette.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: palette.textPrimary),
        tooltip: isHu ? 'Bezárás' : 'Close challenge',
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isHu ? "EKG Gyakorlás" : "ECG Challenge",
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
    );
  }

  Widget _buildHistoryPage(CozyPalette palette, bool isHu) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(Icons.history_edu, color: palette.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              isHu ? "Kórelőzmény" : "Patient History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
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
          isHu
              ? "Kérjük, figyelmesen tekintse át a kórelőzményt és a fenti EKG-t a technikai értelmezés megkezdése előtt."
              : "Review the history and the ECG above carefully before proceeding to the technical interpretation.",
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
