import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
 // For kIsWeb
import 'package:provider/provider.dart';
import '../../services/admin_question_provider.dart';
import 'package:arbor_med/features/analytics/models/ecg_case.dart';
import 'components/ecg_forms/ecg_section_header.dart';
import 'components/ecg_forms/ecg_form_dropdown.dart';
import 'components/ecg_forms/ecg_case_image_picker.dart';
import 'components/ecg_forms/ecg_secondary_diagnoses_selector.dart';
import 'components/ecg_forms/ecg_rhythm_conduction_step.dart';
import 'components/ecg_forms/ecg_morphology_step.dart';
import 'components/ecg_forms/ecg_management_step.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';

import '../../generated/l10n/app_localizations.dart';

import '../../features/ecg/providers/ecg_wizard_state.dart';

class ECGEditorDialog extends StatefulWidget {
  final ECGCase? ecgCase;
  final VoidCallback onSaved;

  const ECGEditorDialog({super.key, this.ecgCase, required this.onSaved});

  @override
  State<ECGEditorDialog> createState() => _ECGEditorDialogState();
}

class _ECGEditorDialogState extends State<ECGEditorDialog> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  final _formKey = GlobalKey<FormState>();

  // Image
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;

  // Metadata
  int? _selectedDiagnosisId;
  List<int> _secondaryDiagnosesIds = [];
  String _difficulty = 'beginner';

  // Template State
  final Set<String> _autofilledFields = {};

  void _markEdited(String key) {
    if (_autofilledFields.contains(key)) {
      setState(() => _autofilledFields.remove(key));
    }
  }

  void _applyTemplate(Map<String, dynamic> findings) {
    setState(() {
      _autofilledFields.clear();

      if (findings.containsKey('rhythm') && findings['rhythm'] is Map) {
        _rhythmRegularity = findings['rhythm']['regularity'] ?? 'Regular';
        _autofilledFields.add('rhythm.regularity');
        _isSinus = findings['rhythm']['sinus'] ?? true;
        _autofilledFields.add('rhythm.sinus');
        _conductionRatio = findings['rhythm']['p_qrs_relation'] ?? '1:1';
        _autofilledFields.add('rhythm.ratio');
      }

      if (findings.containsKey('rate') && findings['rate'] is Map) {
        _rateController.text = findings['rate']['max']?.toString() ?? '';
        _autofilledFields.add('rate.max');
      }

      if (findings.containsKey('conduction') && findings['conduction'] is Map) {
        _prCategory = findings['conduction']['pr_category'] ??
            _mapMsToCategory(findings['conduction']['pr_interval'], 120, 200);
        _autofilledFields.add('conduction.pr');
        _qrsCategory = findings['conduction']['qrs_category'] ??
            _mapMsToCategory(findings['conduction']['qrs_duration'], 0, 120);
        _autofilledFields.add('conduction.qrs');
        _qtCategory = findings['conduction']['qt_category'] ??
            _mapMsToCategory(findings['conduction']['qt_interval'], 0, 440);
        _autofilledFields.add('conduction.qt');
        _avBlock = findings['conduction']['av_block'] ?? 'None';
        _autofilledFields.add('conduction.block');
        _saBlock = findings['conduction']['sa_block'] ??
            (findings['rhythm'] is Map ? findings['rhythm']['sa_block'] : null) ??
            'None';
        _autofilledFields.add('rhythm.sa_block');
      }

      if (findings.containsKey('axis') && findings['axis'] is Map) {
        _axis = findings['axis']['quadrant'] ?? 'Normal';
        _autofilledFields.add('axis');
      }

      if (findings.containsKey('p_wave') && findings['p_wave'] is Map) {
        _pWaveMorph = findings['p_wave']['morphology'] ?? 'Normal';
        _autofilledFields.add('pwave.morph');
        _atrialEnlargement = findings['p_wave']['atrial_enlargement'] ?? 'None';
        _autofilledFields.add('pwave.enlargement');
      }

      if (findings.containsKey('qrs_morph') && findings['qrs_morph'] is Map) {
        _hypertrophy = findings['qrs_morph']['hypertrophy'] ?? 'None';
        _autofilledFields.add('qrs.hypertrophy');
        _bbb = findings['qrs_morph']['bbb'] ?? 'None';
        _autofilledFields.add('qrs.bbb');
        _qWaves = findings['qrs_morph']['q_waves'] ?? 'None';
        _autofilledFields.add('qrs.qwaves');
      }

      if (findings.containsKey('st_t') && findings['st_t'] is Map) {
        _ischemia = findings['st_t']['ischemia'] ?? 'None';
        _autofilledFields.add('st.ischemia');
        _tWave = findings['st_t']['t_wave'] ?? 'Normal';
        _autofilledFields.add('st.twave');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.adminEcgTemplateApplied),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));
  }

  // --- 7+2 STEPS DATA ---

  // Step 0: History
  final TextEditingController _historyController = TextEditingController();

  // Step 1: Rhythm
  String _rhythmRegularity = 'Regular';
  bool _isSinus = true;
  String _conductionRatio = '1:1'; // 1:1, 2:1, Variable, etc

  // Step 2: Rate (Single value for Admin)
  final TextEditingController _rateController = TextEditingController();

  // Step 3: Conduction
  String _prCategory = 'Normal';
  String _qrsCategory = 'Normal';
  String _qtCategory = 'Normal';
  String _avBlock = 'None';
  String _saBlock = 'None';

  // Step 4: Axis
  String _axis = 'Normal';

  // Step 5: P-Wave
  String _pWaveMorph = 'Normal';
  String _atrialEnlargement = 'None';

  // Step 6: QRS Morphology
  String _hypertrophy = 'None';
  String _bbb = 'None';
  String _qWaves = 'None';

  // Step 7: ST-T
  String _ischemia = 'None';
  String _tWave = 'Normal';



  // Step +2: Management (Optional)
  bool _includeManagement = false;
  String _urgency = 'Routine';
  final TextEditingController _managementNotesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing data
    if (widget.ecgCase != null) {
      final c = widget.ecgCase!;
      _existingImageUrl = c.imageUrl;
      _selectedDiagnosisId = c.diagnosisId;
      _secondaryDiagnosesIds = List.from(c.secondaryDiagnosesIds);
      _difficulty = c.difficulty;

      final f = c.findings; // This is a Map<String, dynamic>

      // Step 0: History
      if (f.containsKey('history')) {
        _historyController.text = f['history']?.toString() ?? '';
      }

      // Parse 7+2 structure if available, else fallback or default
      if (f.containsKey('rhythm') && f['rhythm'] is Map) {
        _rhythmRegularity = f['rhythm']['regularity'] ?? 'Regular';
        _isSinus = f['rhythm']['sinus'] ?? true;
        _conductionRatio = f['rhythm']['conduction_ratio'] ??
            f['rhythm']['p_qrs_relation'] ??
            '1:1';
      } else {
        // Fallback legacy
        _rhythmRegularity = f['rhythm'] ?? 'Regular';
      }

      if (f.containsKey('rate')) {
        _rateController.text = (f['rate'] is Map)
            ? (f['rate']['target']?.toString() ??
                f['rate']['max']?.toString() ??
                '')
            : f['rate'].toString();
      }

      if (f.containsKey('conduction') && f['conduction'] is Map) {
        _prCategory = f['conduction']['pr_category'] ??
            _mapMsToCategory(f['conduction']['pr_interval'], 120, 200);
        _qrsCategory = f['conduction']['qrs_category'] ??
            _mapMsToCategory(f['conduction']['qrs_duration'], 0, 120);
        _qtCategory = f['conduction']['qt_category'] ??
            _mapMsToCategory(f['conduction']['qt_interval'], 0, 440);
        _avBlock = f['conduction']['av_block'] ?? 'None';
        _saBlock = f['conduction']['sa_block'] ??
            (f['rhythm'] is Map ? f['rhythm']['sa_block'] : null) ??
            'None';
      } else {
        // Fallback legacy
        if (f['qrs'] == 'Wide') _qrsCategory = 'Prolonged';
      }

      if (f.containsKey('axis')) {
        if (f['axis'] is Map) {
          _axis = f['axis']['quadrant'] ?? f['axis']['deviation'] ?? 'Normal';
        } else {
          _axis = f['axis']?.toString() ?? 'Normal';
        }
      }

      if (f.containsKey('p_wave') && f['p_wave'] is Map) {
        _pWaveMorph = f['p_wave']['morphology'] ?? 'Normal';
        _atrialEnlargement = f['p_wave']['atrial_enlargement'] ??
            f['p_wave']['enlargement'] ??
            'None';
      }

      if (f.containsKey('qrs_morph') && f['qrs_morph'] is Map) {
        _hypertrophy = f['qrs_morph']['hypertrophy'] ?? 'None';
        _bbb = f['qrs_morph']['bbb'] ?? 'None';
        _qWaves = f['qrs_morph']['q_waves'] ?? 'None';
      } else if (f.containsKey('qrs') && f['qrs'] is Map) {
        _hypertrophy = f['qrs']['hypertrophy'] ?? 'None';
        _bbb = f['qrs']['bbb'] ?? 'None';
        _qWaves = f['qrs']['q_waves'] ?? 'None';
      }

      if (f.containsKey('st_t') && f['st_t'] is Map) {
        _ischemia = f['st_t']['ischemia'] ?? 'None';
        _tWave = f['st_t']['t_wave'] ?? 'Normal';
      }

      if (f.containsKey('management') && f['management'] is Map) {
        _includeManagement = true;
        _urgency = f['management']['urgency'] ?? 'Routine';
        _managementNotesController.text = f['management']['notes'] ?? '';
      }
    }

    // Fetch diagnoses just in case
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminQuestionProvider>(context, listen: false).fetchECGDiagnoses();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiagnosisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminEcgSelectDiagnosis)));
      return;
    }
    if (_selectedImage == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminEcgUploadImage)));
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      imageUrl = await ApiService().uploadImage(_selectedImage!);
    }

    if (imageUrl == null) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.adminEcgUploadFailed)));
      }
      return;
    }

    // Construct 7+2 JSON structure
    final parsedRate = int.tryParse(_rateController.text) ?? 60;
    final findings = {
      'history': _historyController.text,
      'rhythm': {
        'regularity': _rhythmRegularity,
        'sinus': _isSinus,
        'conduction_ratio': _conductionRatio,
        'p_qrs_relation': _conductionRatio,
      },
      'rate': {
        'target': parsedRate,
        'min': parsedRate,
        'max': parsedRate,
      },
      'conduction': {
        'pr_category': _prCategory,
        'qrs_category': _qrsCategory,
        'qt_category': _qtCategory,
        'av_block': _avBlock,
        'sa_block': _saBlock,
      },
      'axis': {
        'quadrant': _axis,
        'deviation': _axis,
      },
      'p_wave': {
        'morphology': _pWaveMorph,
        'atrial_enlargement': _atrialEnlargement,
        'enlargement': _atrialEnlargement,
      },
      'qrs_morph': {
        'hypertrophy': _hypertrophy,
        'bbb': _bbb,
        'q_waves': _qWaves,
      },
      'st_t': {'ischemia': _ischemia, 't_wave': _tWave},
    };

    // Add management only if toggled
    if (_includeManagement) {
      findings['management'] = {
        'urgency': _urgency,
        'notes': _managementNotesController.text
      };
    }

    final payload = {
      'diagnosis_id': _selectedDiagnosisId,
      'secondary_diagnoses_ids': _secondaryDiagnosesIds,
      'image_url': imageUrl,
      'difficulty': _difficulty,
      'findings_json': findings,
    };

    if (!mounted) return;
    final questionProvider = Provider.of<AdminQuestionProvider>(context, listen: false);
    bool success;
    if (widget.ecgCase == null) {
      success = await questionProvider.createECGCase(payload);
    } else {
      success = await questionProvider.updateECGCase(widget.ecgCase!.id, payload);
    }

    setState(() => _isUploading = false);

    if (success) {
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorQuestionSaveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 800, // Wider for the 7+2 workflow
        decoration: BoxDecoration(
            color: palette.paperWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color:
                              palette.textSecondary.withValues(alpha: 0.1)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: CozyTheme.of(context)
                                .primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.monitor_heart,
                            color: CozyTheme.of(context).primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                          widget.ecgCase == null
                              ? AppLocalizations.of(context)!.adminEcgNewCase
                              : "${AppLocalizations.of(context)!.adminEcgEditCase.replaceFirst("#{id}", "").trim()} #${widget.ecgCase!.id}",
                          style: CozyTheme.dialogTitle.copyWith(fontSize: 20)),
                    ],
                  ),
                  IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // --- HEADER SECTION: IMAGE & METADATA ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Picker (Left)
                        Expanded(
                          child: EcgCaseImagePicker(
                            selectedImage: _selectedImage,
                            existingImageUrl: _existingImageUrl,
                            onPickImage: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Metadata (Right)
                        Expanded(
                          child: Column(
                            children: [
                              EcgFormDropdown(
                                keyName: AppLocalizations.of(context)!.adminEcgDifficulty,
                                label: AppLocalizations.of(context)!.adminEcgDifficulty,
                                value: _difficulty,
                                items: ECGWizardState.difficulties,
                                icon: Icons.signal_cellular_alt,
                                onChanged: (v) => setState(() => _difficulty = v),
                              ),
                              const SizedBox(height: 16),
                              Consumer<AdminQuestionProvider>(
                                builder: (ctx, stats, _) => DropdownButtonFormField<int>(
                                  initialValue: (_selectedDiagnosisId != null &&
                                          stats.ecgDiagnoses.any((d) => d.id == _selectedDiagnosisId))
                                      ? _selectedDiagnosisId
                                      : null,
                                  decoration: CozyTheme.inputDecoration(
                                    context,
                                    AppLocalizations.of(context)!.adminEcgPrimaryDiagnosis,
                                  ).copyWith(
                                    prefixIcon: const Icon(
                                      Icons.medical_services_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: stats.ecgDiagnoses
                                      .map((d) => DropdownMenuItem(
                                          value: d.id, child: Text("${d.code} - ${d.nameEn}")))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedDiagnosisId = val);
                                    if (val != null) {
                                      final d = stats.ecgDiagnoses.firstWhere((e) => e.id == val);
                                      if (d.standardFindings != null) {
                                        _applyTemplate(d.standardFindings!);
                                      }
                                    }
                                  },
                                  validator: (val) =>
                                      val == null ? AppLocalizations.of(context)!.adminRequired : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              EcgSecondaryDiagnosesSelector(
                                secondaryDiagnosesIds: _secondaryDiagnosesIds,
                                selectedDiagnosisId: _selectedDiagnosisId,
                                onAddDiagnosis: (id) => setState(() => _secondaryDiagnosesIds.add(id)),
                                onRemoveDiagnosis: (id) => setState(() => _secondaryDiagnosesIds.remove(id)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // --- STEP 0: PATIENT HISTORY ---
                    EcgSectionHeader(
                      title: AppLocalizations.of(context)!.adminEcgPatientHistory,
                      icon: Icons.history_edu,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _historyController,
                      maxLines: 2,
                      decoration: _getDecoration(
                        "history",
                        AppLocalizations.of(context)!.adminEcgSignalmentHistory,
                      ).copyWith(
                        hintText: AppLocalizations.of(context)!.adminEcgHistoryHint,
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      ),
                      onChanged: (_) => _markEdited("history"),
                    ),
                    const SizedBox(height: 24),

                    // --- STEPS 1, 2, 3: RHYTHM, RATE, CONDUCTION ---
                    EcgRhythmConductionStep(
                      rhythmRegularity: _rhythmRegularity,
                      conductionRatio: _conductionRatio,
                      isSinus: _isSinus,
                      rateController: _rateController,
                      prCategory: _prCategory,
                      qrsCategory: _qrsCategory,
                      qtCategory: _qtCategory,
                      avBlock: _avBlock,
                      saBlock: _saBlock,
                      bbb: _bbb,
                      autofilledFields: _autofilledFields,
                      onRegularityChanged: (v) => setState(() {
                        _rhythmRegularity = v;
                        _markEdited('rhythm.regularity');
                      }),
                      onConductionRatioChanged: (v) => setState(() {
                        _conductionRatio = v;
                        _markEdited('rhythm.ratio');
                      }),
                      onSinusChanged: (v) => setState(() {
                        _isSinus = v;
                        _markEdited('rhythm.sinus');
                      }),
                      onRateChanged: (_) => _markEdited('rate.max'),
                      onPrCategoryChanged: (v) => setState(() {
                        _prCategory = v;
                        _markEdited('conduction.pr');
                      }),
                      onQrsCategoryChanged: (v) => setState(() {
                        _qrsCategory = v;
                        _markEdited('conduction.qrs');
                      }),
                      onQtCategoryChanged: (v) => setState(() {
                        _qtCategory = v;
                        _markEdited('conduction.qt');
                      }),
                      onAvBlockChanged: (v) => setState(() {
                        _avBlock = v;
                        _markEdited('conduction.block');
                      }),
                      onSaBlockChanged: (v) => setState(() {
                        _saBlock = v;
                        _markEdited('rhythm.sa_block');
                      }),
                      onBbbChanged: (v) => setState(() {
                        _bbb = v;
                        _markEdited('qrs.bbb');
                      }),
                      getDecoration: _getDecoration,
                    ),

                    // --- STEPS 4, 5, 6, 7: MORPHOLOGY (AXIS, P-WAVE, QRS, ST-T) ---
                    EcgMorphologyStep(
                      axis: _axis,
                      pWaveMorph: _pWaveMorph,
                      atrialEnlargement: _atrialEnlargement,
                      hypertrophy: _hypertrophy,
                      bbb: _bbb,
                      qWaves: _qWaves,
                      ischemia: _ischemia,
                      tWave: _tWave,
                      autofilledFields: _autofilledFields,
                      onAxisChanged: (v) => setState(() {
                        _axis = v;
                        _markEdited('axis');
                      }),
                      onPWaveMorphChanged: (v) => setState(() {
                        _pWaveMorph = v;
                        _markEdited('pwave.morph');
                      }),
                      onAtrialEnlargementChanged: (v) => setState(() {
                        _atrialEnlargement = v;
                        _markEdited('pwave.enlargement');
                      }),
                      onHypertrophyChanged: (v) => setState(() {
                        _hypertrophy = v;
                        _markEdited('qrs.hypertrophy');
                      }),
                      onBbbChanged: (v) => setState(() {
                        _bbb = v;
                        _markEdited('qrs.bbb');
                      }),
                      onQWavesChanged: (v) => setState(() {
                        _qWaves = v;
                        _markEdited('qrs.qwaves');
                      }),
                      onIschemiaChanged: (v) => setState(() {
                        _ischemia = v;
                        _markEdited('st.ischemia');
                      }),
                      onTWaveChanged: (v) => setState(() {
                        _tWave = v;
                        _markEdited('st.twave');
                      }),
                    ),

                    // --- STEP +2: MANAGEMENT ---
                    EcgManagementStep(
                      includeManagement: _includeManagement,
                      urgency: _urgency,
                      managementNotesController: _managementNotesController,
                      onIncludeManagementChanged: (v) => setState(() => _includeManagement = v),
                      onUrgencyChanged: (v) => setState(() => _urgency = v),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[100]!))),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.adminEcgSaveCase,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _getDecoration(String key, String label) {
    if (_autofilledFields.contains(key)) {
      return CozyTheme.inputDecoration(context, label).copyWith(
          floatingLabelStyle: const TextStyle(
              backgroundColor: Colors.white,
              color: Colors.green,
              fontWeight: FontWeight.bold),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.green.withValues(alpha: 0.6), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2)));
    }
    return CozyTheme.inputDecoration(context, label).copyWith(
        floatingLabelStyle: TextStyle(
            backgroundColor: CozyTheme.of(context).paperWhite,
            color: CozyTheme.of(context).primary));
  }

  String _mapMsToCategory(dynamic val, int min, int max) {
    if (val == null) return 'Normal';
    final n = int.tryParse(val.toString()) ?? 0;
    if (n == 0) return 'Normal';
    if (n > max) return 'Prolonged';
    if (min > 0 && n < min) return 'Short';
    return 'Normal';
  }
}

