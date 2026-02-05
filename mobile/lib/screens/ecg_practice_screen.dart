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
  final TextEditingController _managementNotesController = TextEditingController();

  // Feedback State
  bool _showFeedback = false;
  Map<String, dynamic>? _feedbackReport;
  final Set<String> _interactedSections = {};
  bool _triedSubmit = false;

  void _markInteracted(String section) {
    if (!_interactedSections.contains(section)) {
      setState(() => _interactedSections.add(section));
    }
  }


  // Static Options (Mirrors Admin)
  final List<String> regularityOpts = ['Regular', 'Irregular', 'Irregularly Irregular'];
  final List<String> conductionOpts = ['1:1', '2:1', '3:1', 'Variable', 'Dissociated'];
  final List<String> intervalOpts = ['Normal', 'Prolonged', 'Short'];
  final List<String> avBlocks = ['None', '1st Degree', '2nd Degree Type I', '2nd Degree Type II', '3rd Degree'];
  final List<String> saBlocks = ['None', 'Sinus Arrest', 'SA Exit Block'];
  final List<String> axisList = ['Normal', 'Left Deviation', 'Right Deviation', 'Extreme'];
  final List<String> pMorphs = ['Normal', 'Peaked', 'Bifid', 'Inverted', 'Absent', 'Sawtooth'];
  final List<String> atrialSizes = ['None', 'Left Atrial', 'Right Atrial', 'Bi-Atrial'];
  final List<String> hypertrophyOpts = ['None', 'LVH', 'RVH', 'Bi-Ventricular'];
  final List<String> bbbOpts = ['None', 'LBBB', 'RBBB', 'IVCD'];
  final List<String> qWaveOpts = ['None', 'Inferior', 'Lateral', 'Anterior', 'Septal'];
  final List<String> ischemiaOpts = ['None', 'ST Elevation', 'ST Depression', 'Hyperacute T'];
  final List<String> tWaveOpts = ['Normal', 'Inverted', 'Flattened', 'Biphasic', 'Peaked'];
  final List<String> urgencyOpts = ['Routine', 'Urgent', 'Emergency'];

  @override
  void initState() {
    super.initState();
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
      _loading = false;
    });
  }

  void _submit() {
    setState(() => _triedSubmit = true);

    // Validation Check: Ensure all dropdowns (non-optional ones) are filled
    final requiredFields = [
      _rhythmRegularity, _conductionRatio, _prCategory, _qrsCategory, _qtCategory,
      _axis, _pWaveMorph, _atrialEnlargement, _hypertrophy, _bbb, _qWaves, _ischemia, _tWave
    ];

    if (requiredFields.any((f) => f.isEmpty) || _rateController.text.isEmpty || _selectedDiagnosisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Some fields are incomplete. Please review the red sections."),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    // Calculate duration
    final duration = DateTime.now().difference(_startTime!);

    // Get standard findings from the master diagnosis list
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final diagnosis = stats.ecgDiagnoses.firstWhere((d) => d.id == _currentCase!.diagnosisId, orElse: () => ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''));
    final standard = diagnosis.standardFindings ?? {};
    
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
      secondaryDxCorrect = expectedSet.difference(selectedSet).isEmpty && selectedSet.difference(expectedSet).isEmpty;
    }

    // Detailed Comparison for Report Card
    final reportData = <String, Map<String, dynamic>>{};
    
    void addReportItem(String key, String title, dynamic userVal, dynamic standardVal) {
      bool correct = false;
      if (key == 'rate' && userVal != null && standardVal != null) {
        final u = int.tryParse(userVal.toString());
        final s = int.tryParse(standardVal.toString());
        if (u != null && s != null) {
          correct = (u - s).abs() <= 5; // +/- 5 BPM Grace Zone
        }
      } else {
        correct = userVal?.toString().toLowerCase() == standardVal?.toString().toLowerCase();
      }

      reportData[key] = {
        'title': title,
        'user': userVal?.toString() ?? 'N/A',
        'standard': standardVal?.toString() ?? 'N/A',
        'isCorrect': correct
      };
    }

    addReportItem('rhythm', 'Rhythm', _rhythmRegularity, standard['rhythm']?['regularity']);
    addReportItem('sinus', 'Sinus Rhythm', _isSinus ? 'Yes' : 'No', standard['rhythm']?['sinus'] == true ? 'Yes' : 'No');
    addReportItem('rate', 'Heart Rate', _rateController.text, standard['rate']?['max']);
    
    // Grading logic for intervals
    addReportItem('pr', 'PR Interval', _prCategory, _mapMsToCategory(standard['conduction']?['pr_interval'], 120, 200));
    addReportItem('qrs', 'QRS Duration', _qrsCategory, _mapMsToCategory(standard['conduction']?['qrs_duration'], 0, 120, isQrs: true));
    addReportItem('qt', 'QT Interval', _qtCategory, _mapMsToCategory(standard['conduction']?['qt_interval'], 0, 440));
    
    addReportItem('av_block', 'AV Block', _avBlock, standard['conduction']?['av_block'] ?? 'None');
    addReportItem('sa_block', 'SA Block', _saBlock, standard['rhythm']?['sa_block'] ?? 'None');
    addReportItem('axis', 'Heart Axis', _axis, standard['axis']?['quadrant']);
    addReportItem('pmorph', 'P-Wave', _pWaveMorph, standard['p_wave']?['morphology']);
    addReportItem('atrial', 'Atrial Enl.', _atrialEnlargement, standard['p_wave']?['atrial_enlargement']);
    addReportItem('hypertrophy', 'Hypertrophy', _hypertrophy, standard['qrs_morph']?['hypertrophy']);
    addReportItem('bbb', 'Bundle Branch', _bbb, standard['qrs_morph']?['bbb']);
    addReportItem('st', 'ST Segment', _ischemia, standard['st_t']?['ischemia']);
    addReportItem('twave', 'T-Wave', _tWave, standard['st_t']?['t_wave']);

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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentCase == null) return const Scaffold(body: Center(child: Text("No ECG cases available.")));

    if (_showFeedback) return _buildReportCard(); // Full screen exit early

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("ECG Challenge", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
            Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    StreamBuilder<int>(
                        stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                        builder: (ctx, snap) {
                            if (_startTime == null || _showFeedback) return const Text("00:00", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
                            final d = DateTime.now().difference(_startTime!);
                            final m = d.inMinutes.toString().padLeft(2, '0');
                            final s = (d.inSeconds % 60).toString().padLeft(2, '0');
                            return Text("$m:$s", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
                        }
                    )
                ])
            )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: [
          // 1. Zoomable Image (Height depends on Image Aspect Ratio)
          Stack(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 6.0,
                    child: Image.network(
                       _currentCase!.imageUrl.startsWith('http') ? _currentCase!.imageUrl : '${ApiService.baseUrl}${_currentCase!.imageUrl}',
                       fit: BoxFit.fitWidth,
                       loadingBuilder: (ctx, child, progress) => progress == null ? child : 
                        const SizedBox(
                          height: 200, 
                          child: Center(child: CircularProgressIndicator(color: CozyTheme.primary))
                        ),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.black54, size: 28),
                      onPressed: _showFullScreenImage,
                      style: IconButton.styleFrom(backgroundColor: Colors.white70),
                  )
              )
            ],
          ),
          
          // 2. Scrollable Form (Bottom)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
              ),
              child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                      _buildSectionHeader("0. Patient History", Icons.history_edu),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CozyTheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CozyTheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          (_currentCase!.findings['history']?.toString().isNotEmpty == true)
                              ? _currentCase!.findings['history']
                              : "No clinical history provided for this case.",
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader("1. Rhythm", Icons.show_chart),
                      const SizedBox(height: 16),
                      Row(children: [
                          Expanded(child: _buildDropdown("Regularity", _rhythmRegularity, regularityOpts, (v) {
                              _rhythmRegularity = v;
                              _markInteracted("rhythm");
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: CheckboxListTile(
                              title: const Text("Sinus Rhythm?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text("P before QRS", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      _buildDropdown("Conduction (e.g. 1:1)", _conductionRatio, conductionOpts, (v) {
                          _conductionRatio = v;
                          _markInteracted("rhythm");
                      }),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader("2. Rate", Icons.timer),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration: CozyTheme.inputDecoration("Heart Rate (BPM)").copyWith(prefixIcon: const Icon(Icons.favorite_border)),
                          onChanged: (_) => _markInteracted("rate"),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader("3. Conduction", Icons.speed),
                      const SizedBox(height: 16),
                      Row(children: [
                          Expanded(child: _buildDropdown("PR Interval", _prCategory, intervalOpts, (v) {
                              _prCategory = v;
                              _markInteracted("conduction");
                          })),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDropdown("QRS Width", _qrsCategory, intervalOpts, (v) {
                              _qrsCategory = v;
                              _markInteracted("conduction");
                          })),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDropdown("QT Interval", _qtCategory, intervalOpts, (v) {
                              _qtCategory = v;
                              _markInteracted("conduction");
                          })),
                      ]),
                      const SizedBox(height: 12),
                      
                      // Conditional Visibility (Option C)
                      if (_prCategory == 'Prolonged') ...[
                        _buildDropdown("AV Block", _avBlock, avBlocks, (v) {
                            _avBlock = v;
                            _markInteracted("conduction");
                        }),
                        const SizedBox(height: 12),
                      ],
                      
                      if (_qrsCategory == 'Prolonged') ...[
                        _buildDropdown("Bundle Branch Block", _bbb, bbbOpts, (v) {
                            _bbb = v;
                            _markInteracted("morphology");
                        }),
                        const SizedBox(height: 12),
                      ],
                      
                      _buildDropdown("SA Block", _saBlock, saBlocks, (v) {
                          _saBlock = v;
                          _markInteracted("conduction");
                      }),
                      const SizedBox(height: 24),

                      _buildSectionHeader("4. Axis", Icons.explore),
                      const SizedBox(height: 16),
                      _buildDropdown("Heart Axis", _axis, axisList, (v) {
                          _axis = v;
                          _markInteracted("axis");
                      }),
                      const SizedBox(height: 24),

                      _buildSectionHeader("5/6/7. Morphology", Icons.graphic_eq),
                      const SizedBox(height: 16),
                      Row(children: [
                           Expanded(child: _buildDropdown("P-Wave", _pWaveMorph, pMorphs, (v) {
                               _pWaveMorph = v;
                               _markInteracted("morphology");
                           })),
                           const SizedBox(width: 12),
                           Expanded(child: _buildDropdown("Atrial Enlargement", _atrialEnlargement, atrialSizes, (v) {
                               _atrialEnlargement = v;
                               _markInteracted("morphology");
                           })),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                           Expanded(child: _buildDropdown("QRS Hypertrophy", _hypertrophy, hypertrophyOpts, (v) {
                               _hypertrophy = v;
                               _markInteracted("morphology");
                           })),
                           const SizedBox(width: 12),
                           Expanded(child: _buildDropdown("Bundle Branch Block", _bbb, bbbOpts, (v) {
                               _bbb = v;
                               _markInteracted("morphology");
                           })),
                      ]),
                      const SizedBox(height: 12),
                      _buildDropdown("Pathological Q-Waves", _qWaves, qWaveOpts, (v) {
                          _qWaves = v;
                          _markInteracted("morphology");
                      }),
                      const SizedBox(height: 12),
                      Row(children: [
                           Expanded(child: _buildDropdown("ST Ischemia", _ischemia, ischemiaOpts, (v) {
                               _ischemia = v;
                               _markInteracted("morphology");
                           })),
                           const SizedBox(width: 12),
                           Expanded(child: _buildDropdown("T-Wave", _tWave, tWaveOpts, (v) {
                               _tWave = v;
                               _markInteracted("morphology");
                           })),
                      ]),
                      const SizedBox(height: 32),

                      const Divider(thickness: 2),
                      const SizedBox(height: 16),
                      const Text("Final Diagnosis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CozyTheme.primary)),
                      const SizedBox(height: 16),
                      _buildDiagnosisSearch(),
                      
                      // Secondary Diagnoses - Only if expected in this case
                      if (_currentCase!.secondaryDiagnosesIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSecondaryDiagnosisSearch(),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Management - Only if defined in the case findings
                      if (_currentCase!.findings['management'] != null) ...[
                        const Divider(thickness: 2),
                        const SizedBox(height: 16),
                        _buildSectionHeader("8. Management", Icons.medical_services),
                        const SizedBox(height: 16),
                        _buildDropdown("Urgency Level", _urgency, urgencyOpts, (v) => _urgency = v),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _managementNotesController,
                            maxLines: 3,
                            decoration: CozyTheme.inputDecoration("Management Notes").copyWith(
                                hintText: "Describe next steps / management..."
                            ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      SizedBox(
                          height: 54,
                          child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: CozyTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4
                              ),
                              child: const Text("SUBMIT ANALYSIS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                          ),
                      ),
                      const SizedBox(height: 48), // Padding for FAB/Bottom
                  ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage() {
    final imageUrl = _currentCase!.imageUrl.startsWith('http') ? _currentCase!.imageUrl : '${ApiService.baseUrl}${_currentCase!.imageUrl}';
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
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
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
    return Row(
      children: [
        Icon(icon, size: 20, color: CozyTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
        const Expanded(child: Divider(indent: 12, height: 24)),
      ],
    );
  }


  Widget _buildDropdown(String label, String value, List<String> items, Function(String) onChanged) {
    bool hasError = _triedSubmit && value.isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hasError ? Colors.red : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: hasError 
            ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2))
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            isExpanded: true,
            hint: Text("Select $label...", style: TextStyle(fontSize: 14, color: hasError ? Colors.red.withValues(alpha: 0.5) : Colors.grey)),
            items: items.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => onChanged(val!)),
          ),
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
            const Text("Secondary Diagnoses", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Autocomplete<ECGDiagnosis>(
              displayStringForOption: (d) => "${d.code} - ${d.nameEn}",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<ECGDiagnosis>.empty();
                final query = textEditingValue.text.toLowerCase();
                return stats.ecgDiagnoses.where((d) => 
                  d.id != _selectedDiagnosisId && 
                  !_selectedSecondaryDiagnoses.contains(d.id) &&
                  (d.nameEn.toLowerCase().contains(query) || d.code.toLowerCase().contains(query))
                );
              },
              onSelected: (ECGDiagnosis selection) {
                setState(() => _selectedSecondaryDiagnoses.add(selection.id));
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: CozyTheme.inputDecoration("Add Secondary Diagnosis").copyWith(
                    prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.grey),
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
                  final d = stats.ecgDiagnoses.firstWhere((e) => e.id == id, orElse: () => ECGDiagnosis(id: id, code: '?', nameEn: 'Unknown', nameHu: ''));
                  return Chip(
                    label: Text(d.code, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _selectedSecondaryDiagnoses.remove(id)),
                    backgroundColor: CozyTheme.primary.withValues(alpha: 0.1),
                    side: BorderSide(color: CozyTheme.primary.withValues(alpha: 0.3)),
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
                      if (textEditingValue.text == '') return const Iterable<ECGDiagnosis>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return stats.ecgDiagnoses.where((d) => 
                        d.nameEn.toLowerCase().contains(query) || 
                        d.nameHu.toLowerCase().contains(query) || 
                        d.code.toLowerCase().contains(query)
                      );
                  },
                  onSelected: (ECGDiagnosis selection) {
                      setState(() => _selectedDiagnosisId = selection.id);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: CozyTheme.inputDecoration("Primary Diagnosis").copyWith(
                              prefixIcon: const Icon(Icons.search),
                              fillColor: Colors.blue[50],
                              filled: true
                          ),
                      );
                  }
              );
          },
      );
  }

  Widget _buildReportCard() {
      final isCorrect = _feedbackReport!['isCorrect'] as bool;
      final score = _feedbackReport!['score'] as int;
      final time = _feedbackReport!['time'] as int;
      final correctDxId = _feedbackReport!['correctDiagnosisId'] as int;
      final primaryCorrect = _feedbackReport!['primary_dx_correct'] as bool;
      final detailed = _feedbackReport!['detailed'] as Map<String, dynamic>;
      
      final stats = Provider.of<StatsProvider>(context, listen: false);
      final diagnosis = stats.ecgDiagnoses.firstWhere((d) => d.id == correctDxId, orElse: () => ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''));

      return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text("Case Review", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
          ),
          body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                 // Score Header
                 Center(
                   child: Column(
                     children: [
                       Icon(
                         isCorrect ? Icons.emoji_events : Icons.assignment_late, 
                         size: 80, 
                         color: isCorrect ? Colors.amber : Colors.orange
                       ),
                       const SizedBox(height: 16),
                       Text(isCorrect ? "Excellent Interpretation!" : "Keep Learning", 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                       ),
                       const SizedBox(height: 4),
                       Text("Time spent: ${time}s", style: TextStyle(color: Colors.grey[600])),
                       const SizedBox(height: 16),
                       Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: List.generate(5, (i) => Icon(
                               Icons.star, 
                               color: i < score ? Colors.amber : Colors.grey[300],
                               size: 32
                           ))
                       ),
                       if (_interactedSections.length < 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Score capped: Interpretation steps skipped.", 
                            style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 32),
                 
                 // Main Diagnosis Result
                 Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                         color: primaryCorrect ? Colors.green[50] : Colors.red[50],
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: primaryCorrect ? Colors.green[200]! : Colors.red[200]!)
                     ),
                     child: Column(children: [
                         Text(primaryCorrect ? "Correct Primary Diagnosis" : "Incorrect Primary Diagnosis", 
                            style: TextStyle(fontSize: 12, color: primaryCorrect ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold)
                         ),
                         const SizedBox(height: 8),
                         Text("${diagnosis.code} - ${diagnosis.nameEn}", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryCorrect ? Colors.green[900] : Colors.red[900]), 
                            textAlign: TextAlign.center
                         ),
                         if (!primaryCorrect)
                           Padding(
                             padding: const EdgeInsets.only(top: 8),
                             child: Text("You suggested a different diagnosis.", style: TextStyle(color: Colors.red[800], fontSize: 13)),
                           )
                     ]),
                 ),

                 const SizedBox(height: 32),
                 
                 // Detailed Comparison Table
                 const Text("Step-by-Step Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.grey[200]!),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: [
                       // Table Header
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                         decoration: BoxDecoration(
                           color: Colors.grey[50],
                           borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                         ),
                         child: const Row(children: [
                           Expanded(flex: 3, child: Text("Interpretation Step", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                           Expanded(flex: 2, child: Text("Your Input", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                           Expanded(flex: 2, child: Text("Expert Findings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                         ]),
                       ),
                       const Divider(height: 1),
                       // Comparison Rows
                       ...detailed.entries.map((e) {
                         final data = e.value as Map<String, dynamic>;
                         final isMatch = data['isCorrect'] as bool;
                         return Column(
                           children: [
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               child: Row(children: [
                                 Expanded(flex: 3, child: Text(data['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                 Expanded(flex: 2, child: Text(data['user'], style: TextStyle(fontSize: 13, color: isMatch ? Colors.green[700] : Colors.red[700]))),
                                 Expanded(flex: 2, child: Text(data['standard'], style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
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
                    const Text("Secondary Findings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Gold Standard Secondary Diagnoses:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _currentCase!.secondaryDiagnosesIds.map((id) {
                               final d = stats.ecgDiagnoses.firstWhere((e) => e.id == id, orElse: () => ECGDiagnosis(id: id, code: '?', nameEn: 'Unknown', nameHu: ''));
                               return Chip(label: Text(d.code), backgroundColor: Colors.white);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                 ],

                 // Management (If correct)
                 if (isCorrect && _currentCase!.findings['management'] != null) ...[
                    const Text("Clinical Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.emergency, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text("Urgency: ${_currentCase!.findings['management']['urgency']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 8),
                          Text(_currentCase!.findings['management']['notes'] ?? "No management notes provided.", style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                 ],

                 ElevatedButton(
                     onPressed: _loadNextCase,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: CozyTheme.primary, 
                       padding: const EdgeInsets.symmetric(vertical: 20),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                     ),
                     child: const Text("CLOSE & START NEXT CASE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
}
