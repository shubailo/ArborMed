import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
 // For kIsWeb
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/common/platform_image.dart';

class ECGEditorDialog extends StatefulWidget {
  final ECGCase? ecgCase;
  final VoidCallback onSaved;

  const ECGEditorDialog({super.key, this.ecgCase, required this.onSaved});

  @override
  State<ECGEditorDialog> createState() => _ECGEditorDialogState();
}

class _ECGEditorDialogState extends State<ECGEditorDialog> {
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
            findings['rhythm']?['sa_block'] ??
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

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Template Applied! Autofilled fields are highlighted."),
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

  // Dropdown Data
  static const difficulties = ['beginner', 'intermediate', 'advanced'];
  static const regularityOpts = [
    'Regular',
    'Irregular',
    'Irregularly Irregular'
  ];
  static const conductionOpts = [
    '1:1',
    '2:1',
    '3:1',
    'Variable',
    'Dissociated'
  ];
  static const intervalOpts = ['Normal', 'Prolonged', 'Short'];
  static const avBlocks = [
    'None',
    '1st Degree',
    '2nd Degree Type I',
    '2nd Degree Type II',
    '3rd Degree'
  ];
  static const saBlocks = ['None', 'Sinus Arrest', 'SA Exit Block'];
  static const axisList = [
    'Normal',
    'Left Deviation',
    'Right Deviation',
    'Extreme Left Deviation',
    'Extreme Right Deviation'
  ];
  static const pMorphs = [
    'Normal',
    'Peaked (Pulmonale)',
    'Bifid (Mitrale)',
    'Inverted',
    'Absent'
  ];
  static const atrialSizes = [
    'None',
    'Left Atrial Enlargement',
    'Right Atrial Enlargement',
    'Bi-atrial Enlargement'
  ];
  static const hypertrophyOpts = ['None', 'LVH', 'RVH', 'Bi-ventricular'];
  static const bbbOpts = [
    'None',
    'RBBB',
    'LBBB',
    'IVCD',
    'Bifascicular',
    'Trifascicular'
  ];
  static const qWaveOpts = [
    'None',
    'Inferior',
    'Anterior',
    'Lateral',
    'Septal'
  ];
  static const ischemiaOpts = [
    'None',
    'ST Depression',
    'ST Elevation (STEMI)',
    'Hyperacute T'
  ];
  static const tWaveOpts = ['Normal', 'Inverted', 'Flattened', 'Peaked'];
  static const urgencyOpts = ['Routine', 'Urgent', 'Emergent'];

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
        _conductionRatio = f['rhythm']['p_qrs_relation'] ?? '1:1';
      } else {
        // Fallback legacy
        _rhythmRegularity = f['rhythm'] ?? 'Regular';
      }

      if (f.containsKey('rate')) {
        _rateController.text = (f['rate'] is Map)
            ? (f['rate']['max']?.toString() ?? '')
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
        _saBlock =
            f['conduction']['sa_block'] ?? f['rhythm']?['sa_block'] ?? 'None';
      } else {
        // Fallback legacy
        if (f['qrs'] == 'Wide') _qrsCategory = 'Prolonged';
      }

      if (f.containsKey('axis') && f['axis'] is Map) {
        _axis = f['axis']['quadrant'] ?? 'Normal';
      } else {
        _axis = f['axis'] ?? 'Normal';
      }

      if (f.containsKey('p_wave') && f['p_wave'] is Map) {
        _pWaveMorph = f['p_wave']['morphology'] ?? 'Normal';
        _atrialEnlargement = f['p_wave']['atrial_enlargement'] ?? 'None';
      }

      if (f.containsKey('qrs_morph') && f['qrs_morph'] is Map) {
        _hypertrophy = f['qrs_morph']['hypertrophy'] ?? 'None';
        _bbb = f['qrs_morph']['bbb'] ?? 'None';
        _qWaves = f['qrs_morph']['q_waves'] ?? 'None';
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
      Provider.of<StatsProvider>(context, listen: false).fetchECGDiagnoses();
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
          const SnackBar(content: Text("Please select a diagnosis")));
      return;
    }
    if (_selectedImage == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload an image")));
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
            .showSnackBar(const SnackBar(content: Text("Image upload failed")));
      }
      return;
    }

    // Construct 7+2 JSON structure
    final findings = {
      'history': _historyController.text,
      'rhythm': {
        'regularity': _rhythmRegularity,
        'sinus': _isSinus,
        'p_qrs_relation': _conductionRatio
      },
      'rate': {
        'min': int.tryParse(_rateController.text) ?? 60,
        'max': int.tryParse(_rateController.text) ?? 60,
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
      },
      'p_wave': {
        'morphology': _pWaveMorph,
        'atrial_enlargement': _atrialEnlargement
      },
      'qrs_morph': {
        'hypertrophy': _hypertrophy,
        'bbb': _bbb,
        'q_waves': _qWaves
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
    final stats = Provider.of<StatsProvider>(context, listen: false);
    bool success;
    if (widget.ecgCase == null) {
      success = await stats.createECGCase(payload);
    } else {
      success = await stats.updateECGCase(widget.ecgCase!.id, payload);
    }

    setState(() => _isUploading = false);

    if (success) {
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to save")));
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
                              ? "New ECG Case (7+2 Steps)"
                              : "Edit Case #${widget.ecgCase!.id}",
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
                        Expanded(child: _buildImagePicker()),
                        const SizedBox(width: 24),
                        // Metadata (Right)
                        Expanded(
                            child: Column(
                          children: [
                            _buildDropdown(
                                "difficulty",
                                "Difficulty",
                                _difficulty,
                                difficulties,
                                (v) => _difficulty = v,
                                Icons.signal_cellular_alt),
                            const SizedBox(height: 16),
                            Consumer<StatsProvider>(
                              builder: (ctx, stats, _) =>
                                  DropdownButtonFormField<int>(
                                initialValue: _selectedDiagnosisId,
                                decoration: CozyTheme.inputDecoration(
                                        context, "Primary Diagnosis")
                                    .copyWith(
                                        prefixIcon: const Icon(
                                            Icons.medical_services_outlined,
                                            color: Colors.grey)),
                                isExpanded: true,
                                items: stats.ecgDiagnoses
                                    .map((d) => DropdownMenuItem(
                                        value: d.id,
                                        child: Text("${d.code} - ${d.nameEn}")))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedDiagnosisId = val);
                                  if (val != null) {
                                    final d = stats.ecgDiagnoses
                                        .firstWhere((e) => e.id == val);
                                    if (d.standardFindings != null) {
                                      _applyTemplate(d.standardFindings!);
                                    }
                                  }
                                },
                                validator: (val) =>
                                    val == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSecondaryDiagnosesSelector(),
                          ],
                        ))
                      ],
                    ),

                    // --- STEP 0: PATIENT HISTORY ---
                    _buildSectionHeader(
                        "0. Patient History (Optional)", Icons.history_edu),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _historyController,
                      maxLines: 2,
                      decoration: _getDecoration(
                              "history", "Patient Signalment / History")
                          .copyWith(
                        hintText: "e.g. 55M, chest pain for 2 hours...",
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.grey),
                      ),
                      onChanged: (_) => _markEdited("history"),
                    ),
                    const SizedBox(height: 24),

                    // --- STEP 1: RHYTHM ---
                    _buildSectionHeader("1. Rhythm", Icons.show_chart),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 3,
                            child: _buildDropdown(
                                "rhythm.regularity",
                                "Regularity",
                                _rhythmRegularity,
                                regularityOpts, (v) {
                              _rhythmRegularity = v;
                              _markEdited('rhythm.regularity');
                            }, Icons.linear_scale)),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 3,
                            child: _buildDropdown("rhythm.ratio", "Ratio",
                                _conductionRatio, conductionOpts, (v) {
                              _conductionRatio = v;
                              _markEdited('rhythm.ratio');
                            }, Icons.compare_arrows)),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 4,
                            child: _autofillWrapper(
                              "rhythm.sinus",
                              InputDecorator(
                                decoration: _getDecoration(
                                        "rhythm.sinus", "Sinus Rhythm?")
                                    .copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 0),
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: _isSinus,
                                        onChanged: (v) {
                                          setState(() => _isSinus = v!);
                                          _markEdited('rhythm.sinus');
                                        },
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const Expanded(
                                      child: Text(
                                          "P before QRS, positive in II",
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- STEP 2: RATE ---
                    _buildSectionHeader("2. Heart Rate", Icons.timer),
                    const SizedBox(height: 16),
                    _autofillWrapper(
                        "rate.max",
                        TextFormField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration:
                              _getDecoration("rate.max", "Heart Rate (BPM)")
                                  .copyWith(
                                      prefixIcon: const Icon(Icons.favorite),
                                      helperText:
                                          "Students get +/- 5 BPM grace zone"),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onChanged: (_) => _markEdited('rate.max'),
                        )),
                    const SizedBox(height: 24),

                    // --- STEP 3: CONDUCTION ---
                    _buildSectionHeader("3. Conduction", Icons.speed),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _buildDropdown("conduction.pr", "PR Interval",
                              _prCategory, intervalOpts, (v) {
                        _prCategory = v;
                        _markEdited('conduction.pr');
                      }, Icons.timer_outlined)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown("conduction.qrs", "QRS Width",
                              _qrsCategory, intervalOpts, (v) {
                        _qrsCategory = v;
                        _markEdited('conduction.qrs');
                      }, Icons.width_normal)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown("conduction.qt", "QT Interval",
                              _qtCategory, intervalOpts, (v) {
                        _qtCategory = v;
                        _markEdited('conduction.qt');
                      }, Icons.av_timer)),
                    ]),
                    const SizedBox(height: 16),

                    // Conditional Blocks
                    if (_prCategory == 'Prolonged') ...[
                      _buildDropdown(
                          "conduction.block", "AV Block", _avBlock, avBlocks,
                          (v) {
                        _avBlock = v;
                        _markEdited('conduction.block');
                      }, Icons.block),
                      const SizedBox(height: 16),
                    ],

                    if (_qrsCategory == 'Prolonged') ...[
                      _buildDropdown(
                          "qrs.bbb", "Bundle Branch Block", _bbb, bbbOpts, (v) {
                        _bbb = v;
                        _markEdited('qrs.bbb');
                      }, Icons.timeline),
                      const SizedBox(height: 16),
                    ],

                    _buildDropdown(
                        "rhythm.sa_block", "SA Block", _saBlock, saBlocks, (v) {
                      _saBlock = v;
                      _markEdited('rhythm.sa_block');
                    }, Icons.timer_off),
                    const SizedBox(height: 24),

                    // --- STEP 4: AXIS ---
                    _buildSectionHeader("4. Axis", Icons.explore),
                    const SizedBox(height: 16),
                    _buildDropdown("axis", "Heart Axis", _axis, axisList, (v) {
                      _axis = v;
                      _markEdited('axis');
                    }, Icons.compass_calibration),
                    const SizedBox(height: 24),

                    // --- STEP 5: P-WAVE ---
                    _buildSectionHeader("5. P-Wave Morphology", Icons.waves),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _buildDropdown(
                              "pwave.morph", "Morphology", _pWaveMorph, pMorphs,
                              (v) {
                        _pWaveMorph = v;
                        _markEdited('pwave.morph');
                      }, Icons.tune)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown(
                              "pwave.enlargement",
                              "Atrial Enlargement",
                              _atrialEnlargement,
                              atrialSizes, (v) {
                        _atrialEnlargement = v;
                        _markEdited('pwave.enlargement');
                      }, Icons.zoom_out_map)),
                    ]),
                    const SizedBox(height: 24),

                    // --- STEP 6: QRS MORPHOLOGY ---
                    _buildSectionHeader("6. QRS Morphology", Icons.graphic_eq),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _buildDropdown(
                              "qrs.hypertrophy",
                              "Hypertrophy",
                              _hypertrophy,
                              hypertrophyOpts, (v) {
                        _hypertrophy = v;
                        _markEdited('qrs.hypertrophy');
                      }, Icons.line_weight)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown(
                              "qrs.bbb", "Bundle Branch Block", _bbb, bbbOpts,
                              (v) {
                        _bbb = v;
                        _markEdited('qrs.bbb');
                      }, Icons.timeline)),
                    ]),
                    const SizedBox(height: 16),
                    _buildDropdown("qrs.qwaves", "Pathological Q Waves",
                        _qWaves, qWaveOpts, (v) {
                      _qWaves = v;
                      _markEdited('qrs.qwaves');
                    }, Icons.priority_high),
                    const SizedBox(height: 24),

                    // --- STEP 7: ST-T MORPHOLOGY ---
                    _buildSectionHeader(
                        "7. ST-T Morphology", Icons.trending_up),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _buildDropdown(
                              "st.ischemia",
                              "Ischemia/Infarction",
                              _ischemia,
                              ischemiaOpts, (v) {
                        _ischemia = v;
                        _markEdited('st.ischemia');
                      }, Icons.warning_amber)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown(
                              "st.twave", "T-Wave", _tWave, tWaveOpts, (v) {
                        _tWave = v;
                        _markEdited('st.twave');
                      }, Icons.waves)),
                    ]),
                    const SizedBox(height: 24),

                    // --- STEP +2: MANAGEMENT ---
                    Container(
                      decoration: BoxDecoration(
                          color: _includeManagement
                              ? Colors.orange.withValues(alpha: 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _includeManagement
                              ? Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3))
                              : null),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                                "Include Step +2: Management & Urgency?"),
                            subtitle: const Text(
                                "Only for intermediate/advanced cases"),
                            value: _includeManagement,
                            onChanged: (v) =>
                                setState(() => _includeManagement = v),
                            activeThumbColor: Colors.orange,
                          ),
                          if (_includeManagement) ...[
                            const SizedBox(height: 16),
                            _buildDropdown(
                                "management.urgency",
                                "Urgency Level",
                                _urgency,
                                urgencyOpts,
                                (v) => _urgency = v,
                                Icons.notification_important),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _managementNotesController,
                              maxLines: 3,
                              decoration: CozyTheme.inputDecoration(
                                      context, "Notes / Next Steps")
                                  .copyWith(
                                      prefixIcon: const Icon(Icons.note_add,
                                          color: Colors.grey),
                                      helperText:
                                          "E.g., Refer to Cardiology, Start Beta Blocker"),
                            ),
                          ]
                        ],
                      ),
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
                      : const Text("Save 7+2 Case",
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: CozyTheme.of(context).primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 2, color: Colors.grey[100])),
      ],
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

  Widget _autofillWrapper(String key, Widget child) {
    if (!_autofilledFields.contains(key)) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: 12,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child:
                const Icon(Icons.auto_awesome, size: 14, color: Colors.green),
          ),
        )
      ],
    );
  }

  Widget _buildDropdown(String key, String label, String value,
      List<String> items, Function(String) onChanged, IconData icon) {
    return _autofillWrapper(
        key,
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _getDecoration(key, label).copyWith(
              prefixIcon: Icon(icon, color: Colors.grey),
              errorStyle: const TextStyle(height: 0),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
          items: items
              .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => onChanged(val!)),
        ));
  }

  Widget _buildImagePicker() {
    final palette = CozyTheme.of(context);
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _selectedImage == null && _existingImageUrl == null
              ? palette.surface
              : palette.paperWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _selectedImage == null && _existingImageUrl == null
                  ? palette.primary.withValues(alpha: 0.5)
                  : palette.textSecondary.withValues(alpha: 0.3),
              style: BorderStyle.solid,
              width: 2),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlatformImage(path: _selectedImage!.path, fit: BoxFit.cover),
                    Container(color: Colors.black12),
                    const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 40))
                  ],
                ))
            : (_existingImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _existingImageUrl!.startsWith('http')
                              ? _existingImageUrl!
                              : '${ApiService.baseUrl}$_existingImageUrl',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, _, __) => const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey)),
                        ),
                        Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black26)
                                  ]),
                              child: Icon(Icons.edit,
                                  size: 20,
                                  color: CozyTheme.of(context).primary),
                            ))
                      ],
                    ))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: CozyTheme.of(context)
                                .primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.cloud_upload_outlined,
                            size: 32, color: CozyTheme.of(context).primary),
                      ),
                      const SizedBox(height: 12),
                      const Text("Click to upload ECG Strip",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  )),
      ),
    );
  }

  Widget _buildSecondaryDiagnosesSelector() {
    return Consumer<StatsProvider>(builder: (ctx, stats, _) {
      return InkWell(
        onTap: () => _showDiagnosisSelector(stats),
        child: InputDecorator(
          decoration: CozyTheme.inputDecoration(context, "Secondary Diagnoses")
              .copyWith(
            prefixIcon:
                const Icon(Icons.playlist_add_check, color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: _secondaryDiagnosesIds.isEmpty
              ? const Text("None (Tap to add)",
                  style: TextStyle(color: Colors.grey, fontSize: 14))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _secondaryDiagnosesIds.map((id) {
                    final d = stats.ecgDiagnoses.firstWhere((e) => e.id == id,
                        orElse: () => ECGDiagnosis(
                            id: id, code: '?', nameEn: 'Unknown', nameHu: ''));
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: CozyTheme.of(context)
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: CozyTheme.of(context)
                                  .primary
                                  .withValues(alpha: 0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(d.code,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: CozyTheme.of(context).primary)),
                          const SizedBox(width: 4),
                          InkWell(
                              onTap: () => setState(
                                  () => _secondaryDiagnosesIds.remove(id)),
                              child: Icon(Icons.close,
                                  size: 14,
                                  color: CozyTheme.of(context).primary))
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      );
    });
  }

  void _showDiagnosisSelector(StatsProvider stats) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add Secondary Diagnosis",
                  style: CozyTheme.of(context).dialogTitle),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: stats.ecgDiagnoses
                      .where((d) =>
                          d.id != _selectedDiagnosisId &&
                          !_secondaryDiagnosesIds.contains(d.id))
                      .map((d) {
                    return ListTile(
                      dense: true,
                      trailing:
                          Icon(Icons.add, color: CozyTheme.of(context).primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      title: Text("${d.code} - ${d.nameEn}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(d.nameHu.isNotEmpty ? d.nameHu : '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        setState(() => _secondaryDiagnosesIds.add(d.id));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"))
            ],
          ),
        ),
      ),
    );
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
