import 'package:flutter/material.dart';

class ECGWizardState extends ChangeNotifier {
  // Static Options Arrays
  static const List<String> difficulties = ['beginner', 'intermediate', 'advanced'];
  static const List<String> regularityOpts = [
    'Regular',
    'Irregular',
    'Irregularly Irregular'
  ];
  static const List<String> conductionOpts = [
    '1:1',
    '2:1',
    '3:1',
    'Variable',
    'Dissociated'
  ];
  static const List<String> intervalOpts = ['Normal', 'Prolonged', 'Short'];
  static const List<String> avBlocks = [
    'None',
    '1st Degree',
    '2nd Degree Type I',
    '2nd Degree Type II',
    '3rd Degree'
  ];
  static const List<String> saBlocks = ['None', 'Sinus Arrest', 'SA Exit Block'];
  static const List<String> axisList = [
    'Normal',
    'Left Deviation',
    'Right Deviation',
    'Extreme Left Deviation',
    'Extreme Right Deviation'
  ];
  static const List<String> pMorphs = [
    'Normal',
    'Peaked (Pulmonale)',
    'Bifid (Mitrale)',
    'Inverted',
    'Absent'
  ];
  static const List<String> atrialSizes = [
    'None',
    'Left Atrial Enlargement',
    'Right Atrial Enlargement',
    'Bi-atrial Enlargement'
  ];
  static const List<String> hypertrophyOpts = ['None', 'LVH', 'RVH', 'Bi-ventricular'];
  static const List<String> bbbOpts = [
    'None',
    'RBBB',
    'LBBB',
    'IVCD',
  ];
  static const List<String> qWaveOpts = [
    'None',
    'Inferior',
    'Anterior',
    'Lateral',
    'Septal'
  ];
  static const List<String> ischemiaOpts = [
    'None',
    'ST Elevation',
    'ST Depression',
    'T Wave Inversion',
    'Hyperacute T Waves'
  ];
  static const List<String> tWaveOpts = [
    'Normal',
    'Peaked',
    'Inverted',
    'Flattened',
    'Biphasic'
  ];
  static const List<String> urgencyOpts = ['Routine', 'Urgent', 'Emergency'];

  // Step 0: History & Config
  String history = '';
  String difficulty = 'beginner';

  // Step 1: Rhythm
  String rhythmRegularity = 'Regular';
  bool isSinus = true;
  String conductionRatio = '1:1';

  // Step 2: Rate
  String rate = '';

  // Step 3: Conduction
  String prCategory = 'Normal';
  String qrsCategory = 'Normal';
  String qtCategory = 'Normal';
  String avBlock = 'None';
  String saBlock = 'None';

  // Step 4: Axis
  String axis = 'Normal';

  // Step 5: P-Wave
  String pWaveMorph = 'Normal';
  String atrialEnlargement = 'None';

  // Step 6: QRS Morphology
  String hypertrophy = 'None';
  String bbb = 'None';
  String qWaves = 'None';

  // Step 7: ST-T
  String ischemia = 'None';
  String tWave = 'Normal';

  // Result / Meta Steps
  int? selectedDiagnosisId;
  List<int> secondaryDiagnosesIds = [];
  String urgency = 'Routine';
  String managementNotes = '';

  // Helper flags
  final Set<String> autofilledFields = {};

  void markEdited(String key) {
    if (autofilledFields.contains(key)) {
      autofilledFields.remove(key);
      notifyListeners();
    }
  }

  void updateField<T>(String key, void Function() updateBlock) {
    updateBlock();
    markEdited(key);
    notifyListeners();
  }

  void setRhythmRegularity(String val) => updateField('rhythm.regularity', () => rhythmRegularity = val);
  void setSinus(bool val) => updateField('rhythm.sinus', () => isSinus = val);
  void setConductionRatio(String val) => updateField('rhythm.ratio', () => conductionRatio = val);
  void setRate(String val) => updateField('rate.max', () => rate = val);
  void setPrCategory(String val) => updateField('conduction.pr', () => prCategory = val);
  void setQrsCategory(String val) => updateField('conduction.qrs', () => qrsCategory = val);
  void setQtCategory(String val) => updateField('conduction.qt', () => qtCategory = val);
  void setAvBlock(String val) => updateField('conduction.block', () => avBlock = val);
  void setSaBlock(String val) => updateField('rhythm.sa_block', () => saBlock = val);
  void setAxis(String val) => updateField('axis', () => axis = val);
  void setPWaveMorph(String val) => updateField('pwave.morph', () => pWaveMorph = val);
  void setAtrialEnlargement(String val) => updateField('pwave.enlargement', () => atrialEnlargement = val);
  void setHypertrophy(String val) => updateField('qrs.hypertrophy', () => hypertrophy = val);
  void setBbb(String val) => updateField('qrs.bbb', () => bbb = val);
  void setQWaves(String val) => updateField('qrs.qwaves', () => qWaves = val);
  void setIschemia(String val) => updateField('st.ischemia', () => ischemia = val);
  void setTWave(String val) => updateField('st.twave', () => tWave = val);
  void setUrgency(String val) => updateField('urgency', () => urgency = val);
  void setDifficulty(String val) => updateField('difficulty', () => difficulty = val);
  void setHistory(String val) {
    history = val;
    notifyListeners();
  }
  void setManagementNotes(String val) {
    managementNotes = val;
    notifyListeners();
  }
  void setPrimaryDiagnosis(int? id) {
    selectedDiagnosisId = id;
    notifyListeners();
  }
  void toggleSecondaryDiagnosis(int id) {
    if (secondaryDiagnosesIds.contains(id)) {
      secondaryDiagnosesIds.remove(id);
    } else {
      secondaryDiagnosesIds.add(id);
    }
    notifyListeners();
  }

  void populateFromFindings(Map<String, dynamic> findings) {
    autofilledFields.clear();

    String mapMsToCategory(dynamic msValue, int minNorm, int maxNorm) {
        if (msValue == null) return 'Normal';
        final v = double.tryParse(msValue.toString());
        if (v == null) return 'Normal';
        if (v < minNorm) return 'Short';
        if (v > maxNorm) return 'Prolonged';
        return 'Normal';
    }

    if (findings.containsKey('rhythm') && findings['rhythm'] is Map) {
      rhythmRegularity = findings['rhythm']['regularity'] ?? 'Regular';
      autofilledFields.add('rhythm.regularity');
      isSinus = findings['rhythm']['sinus'] ?? true;
      autofilledFields.add('rhythm.sinus');
      conductionRatio = findings['rhythm']['p_qrs_relation'] ?? '1:1';
      autofilledFields.add('rhythm.ratio');
    }

    if (findings.containsKey('rate') && findings['rate'] is Map) {
      rate = findings['rate']['max']?.toString() ?? '';
      autofilledFields.add('rate.max');
    }

    if (findings.containsKey('conduction') && findings['conduction'] is Map) {
      prCategory = findings['conduction']['pr_category'] ??
          mapMsToCategory(findings['conduction']['pr_interval'], 120, 200);
      autofilledFields.add('conduction.pr');
      qrsCategory = findings['conduction']['qrs_category'] ??
          mapMsToCategory(findings['conduction']['qrs_duration'], 0, 120);
      autofilledFields.add('conduction.qrs');
      qtCategory = findings['conduction']['qt_category'] ??
          mapMsToCategory(findings['conduction']['qt_interval'], 0, 440);
      autofilledFields.add('conduction.qt');
      avBlock = findings['conduction']['av_block'] ?? 'None';
      autofilledFields.add('conduction.block');
      saBlock = findings['conduction']['sa_block'] ??
          findings['rhythm']?['sa_block'] ??
          'None';
      autofilledFields.add('rhythm.sa_block');
    }

    if (findings.containsKey('axis') && findings['axis'] is Map) {
      axis = findings['axis']['quadrant'] ?? 'Normal';
      autofilledFields.add('axis');
    }

    if (findings.containsKey('p_wave') && findings['p_wave'] is Map) {
      pWaveMorph = findings['p_wave']['morphology'] ?? 'Normal';
      autofilledFields.add('pwave.morph');
      atrialEnlargement = findings['p_wave']['atrial_enlargement'] ?? 'None';
      autofilledFields.add('pwave.enlargement');
    }

    if (findings.containsKey('qrs_morph') && findings['qrs_morph'] is Map) {
      hypertrophy = findings['qrs_morph']['hypertrophy'] ?? 'None';
      autofilledFields.add('qrs.hypertrophy');
      bbb = findings['qrs_morph']['bbb'] ?? 'None';
      autofilledFields.add('qrs.bbb');
      qWaves = findings['qrs_morph']['q_waves'] ?? 'None';
      autofilledFields.add('qrs.qwaves');
    }

    if (findings.containsKey('st_t') && findings['st_t'] is Map) {
      ischemia = findings['st_t']['ischemia'] ?? 'None';
      autofilledFields.add('st.ischemia');
      tWave = findings['st_t']['t_wave'] ?? 'Normal';
      autofilledFields.add('st.twave');
    }

    notifyListeners();
  }

  void loadFromCase(dynamic ecgCase) {
    if (ecgCase == null) return;
    
    // We expect ecgCase to have these properties or pass the map equivalent.
    // The specifics of reading from ECGCase will trigger this, implemented in the views calling this.
    // e.g. history = ecgCase.findings['history'] ?? '';
    // We leave this loosely coupled to avoid depending on specific Admin vs Practice models if they differ.
  }
}
