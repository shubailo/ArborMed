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
import '../../theme/cozy_theme.dart';

import '../../generated/l10n/app_localizations.dart';

import '../../features/ecg/providers/ecg_wizard_state.dart';
import '../../features/ecg/models/ecg_editor_form_data.dart';

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
  bool _isPickingImage = false;
  String? _saveError;

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
        _conductionRatio = findings['rhythm']['conduction_ratio'] ?? findings['rhythm']['p_qrs_relation'] ?? '1:1';
        _autofilledFields.add('rhythm.ratio');
      }

      if (findings.containsKey('rate') && findings['rate'] is Map) {
        final rate = findings['rate'];
        _rateController.text = (rate['target'] ?? rate['max'] ?? rate['min'])?.toString() ?? '';
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

      final data = ECGEditorFormData.fromFindings(c.findings);
      _historyController.text = data.history;
      _rhythmRegularity = data.rhythmRegularity;
      _isSinus = data.isSinus;
      _conductionRatio = data.conductionRatio;
      if (c.findings['rate'] != null) _rateController.text = data.rate.toString();
      _prCategory = data.prCategory;
      _qrsCategory = data.qrsCategory;
      _qtCategory = data.qtCategory;
      _avBlock = data.avBlock;
      _saBlock = data.saBlock;
      _axis = data.axis;
      _pWaveMorph = data.pWaveMorph;
      _atrialEnlargement = data.atrialEnlargement;
      _hypertrophy = data.hypertrophy;
      _bbb = data.bbb;
      _qWaves = data.qWaves;
      _ischemia = data.ischemia;
      _tWave = data.tWave;
      _includeManagement = data.includeManagement;
      _urgency = data.urgency;
      _managementNotesController.text = data.managementNotes;
    }

    // Fetch diagnoses just in case
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminQuestionProvider>().fetchECGDiagnoses();
    });
  }

  String? _validateRate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return widget.ecgCase != null && widget.ecgCase!.findings['rate'] == null
          ? null : l10n.adminRequired;
    }
    final rate = int.tryParse(text);
    return rate != null && rate > 0 ? null : l10n.adminEcgInvalidRate;
  }

  @override
  void dispose() {
    _historyController.dispose();
    _rateController.dispose();
    _managementNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isUploading) return;
    setState(() {
      _isPickingImage = true;
      _saveError = null;
    });
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (mounted && image != null) {
        setState(() {
          _selectedImage = image;
          _existingImageUrl = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saveError = l10n.adminEcgUploadFailed);
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save() async {
    if (_isUploading || _isPickingImage) return;
    if (!_formKey.currentState!.validate()) return;
    final rateError = _validateRate(_rateController.text);
    if (rateError != null) {
      setState(() => _saveError = rateError);
      return;
    }
    if (_selectedDiagnosisId == null) {
      setState(() => _saveError = l10n.adminEcgSelectDiagnosis);
      return;
    }
    if (_selectedImage == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      setState(() => _saveError = l10n.adminEcgUploadImage);
      return;
    }

    setState(() {
      _isUploading = true;
      _saveError = null;
    });

    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      imageUrl = await context.read<AdminQuestionProvider>().apiService.uploadImage(_selectedImage!);
      if (!mounted) return;
      if (imageUrl != null) {
        _existingImageUrl = imageUrl;
        _selectedImage = null;
      }
    }

    if (imageUrl == null) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _saveError = l10n.adminEcgUploadFailed;
        });
      }
      return;
    }

    final data = ECGEditorFormData(
      history: _historyController.text, rhythmRegularity: _rhythmRegularity,
      isSinus: _isSinus, conductionRatio: _conductionRatio,
      rate: int.tryParse(_rateController.text.trim()) ?? 60,
      prCategory: _prCategory, qrsCategory: _qrsCategory, qtCategory: _qtCategory,
      avBlock: _avBlock, saBlock: _saBlock, axis: _axis, pWaveMorph: _pWaveMorph,
      atrialEnlargement: _atrialEnlargement, hypertrophy: _hypertrophy, bbb: _bbb,
      qWaves: _qWaves, ischemia: _ischemia, tWave: _tWave,
      includeManagement: _includeManagement, urgency: _urgency, managementNotes: _managementNotesController.text,
    );
    final original = widget.ecgCase?.findings;
    final findings = original == null ? data.toFindingsJson() : data.applyTo(original,
        rateEntered: original['rate'] == null && _rateController.text.trim().isNotEmpty);

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

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _saveError = l10n.adminEcgSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return PopScope(canPop: !_isUploading, child: Dialog(
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
                      onPressed: _isUploading ? null : () => Navigator.pop(context)),
                ],
              ),
            ),

            Expanded(
              child: ExcludeFocus(excluding: _isUploading, child: AbsorbPointer(absorbing: _isUploading, child: Form(
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
                            onPickImage: _isUploading || _isPickingImage ? null : _pickImage,
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
                                builder: (ctx, stats, _) => stats.ecgDiagnosesFailed
                                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(l10n.adminEcgDiagnosesLoadFailed),
                                        TextButton.icon(onPressed: stats.fetchECGDiagnoses, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
                                      ])
                                    : DropdownButtonFormField<int>(
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
                                          value: d.id, child: Text("${d.code} - ${Localizations.localeOf(context).languageCode == 'hu' && d.nameHu.isNotEmpty ? d.nameHu : d.nameEn}")))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedDiagnosisId = val;
                                      _secondaryDiagnosesIds.remove(val);
                                    });
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
                      validateRate: _validateRate,
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
              ))),
            ),
            if (_saveError != null) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(container: true, liveRegion: true, child: Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
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
                  onPressed: _isUploading || _isPickingImage ? null : _save,
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
    ));
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

