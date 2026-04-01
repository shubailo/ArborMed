import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';
import 'package:get_it/get_it.dart';

import '../widgets/ecg_wizard/ecg_history_step.dart';
import '../widgets/ecg_wizard/ecg_interpretation_step.dart';
import '../widgets/ecg_wizard/ecg_conduction_step.dart';
import '../widgets/ecg_wizard/ecg_morphology_step.dart';
import '../widgets/ecg_wizard/ecg_diagnosis_step.dart';
import '../widgets/ecg_report_card.dart';

class ECGPracticeScreen extends StatefulWidget {
  const ECGPracticeScreen({super.key});

  @override
  State<ECGPracticeScreen> createState() => _ECGPracticeScreenState();
}

class _ECGPracticeScreenState extends State<ECGPracticeScreen> {
  final PageController _pageController = PageController();
  final ECGContract _ecgContract = GetIt.instance<ECGContract>();

  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = true;
  bool _isSubmitted = false;
  ECGResult? _submissionResult;

  // Data
  ECGCase? _currentCase;
  List<ECGDiagnosis> _diagnoses = [];

  // Session State
  final Map<String, dynamic> _userFindings = {};
  int? _selectedDiagnosisId;
  final List<int> _secondaryDiagnosisIds = [];
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final diagnoses = await _ecgContract.fetchDiagnoses();
      final cases = await _ecgContract.fetchECGCases();
      
      if (mounted) {
        setState(() {
          _diagnoses = diagnoses;
          if (cases.isNotEmpty) {
            _currentCase = cases.first; // Load first case for now
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ECG data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateFinding(String key, dynamic value) {
    setState(() {
      _userFindings[key] = value;
    });
  }

  void _submit() {
    if (_currentCase == null || _selectedDiagnosisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a primary diagnosis.')),
      );
      return;
    }

    final result = ECGResult(
      caseId: _currentCase!.id,
      diagnosisId: _selectedDiagnosisId!,
      userFindings: _userFindings,
      duration: DateTime.now().difference(_startTime),
      timestamp: DateTime.now(),
    );

    _ecgContract.submitResult(result);
    
    setState(() {
      _isSubmitted = true;
      _submissionResult = result;
    });
  }

  void _nextStep() {
    if (_currentStep == _totalSteps - 1) {
      _submit();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentCase == null) {
      return const Scaffold(body: Center(child: Text('No ECG cases available.')));
    }

    final palette = CozyTheme.of(context);

    if (_isSubmitted && _submissionResult != null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text('Practice Result'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: ECGReportCard(
            result: _submissionResult!,
            ecgCase: _currentCase!,
            allDiagnoses: _diagnoses,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('ECG Interpretation Wizard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(palette),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                ECGHistoryStep(ecgCase: _currentCase!),
                ECGInterpretationStep(
                  userFindings: _userFindings,
                  onUpdate: _updateFinding,
                ),
                ECGConductionStep(
                  userFindings: _userFindings,
                  onUpdate: _updateFinding,
                ),
                ECGMorphologyStep(
                  userFindings: _userFindings,
                  onUpdate: _updateFinding,
                ),
                ECGDiagnosisStep(
                  diagnoses: _diagnoses,
                  selectedDiagnosisId: _selectedDiagnosisId,
                  secondaryDiagnosisIds: _secondaryDiagnosisIds,
                  onPrimarySelect: (id) => setState(() => _selectedDiagnosisId = id),
                  onSecondaryToggle: (id) {
                    setState(() {
                      if (_secondaryDiagnosisIds.contains(id)) {
                        _secondaryDiagnosisIds.remove(id);
                      } else {
                        _secondaryDiagnosisIds.add(id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          _buildBottomNav(palette),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(CozyPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? palette.primary : palette.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav(CozyPalette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: palette.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('PREVIOUS', style: TextStyle(color: palette.primary)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'SUBMIT EVALUATION' : 'CONTINUE',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
