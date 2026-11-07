import 'package:flutter/foundation.dart';

/// Immutable model representing ECG case editor form data.
/// Encapsulates the 7+2 systematic ECG analysis steps and handles
/// JSON findings serialization and parsing across both legacy and modern formats.
@immutable
class ECGEditorFormData {
  final String history;
  final String rhythmRegularity;
  final bool isSinus;
  final String conductionRatio;
  final int rate;
  final String prCategory;
  final String qrsCategory;
  final String qtCategory;
  final String avBlock;
  final String saBlock;
  final String axis;
  final String pWaveMorph;
  final String atrialEnlargement;
  final String hypertrophy;
  final String bbb;
  final String qWaves;
  final String ischemia;
  final String tWave;
  final bool includeManagement;
  final String urgency;
  final String managementNotes;

  const ECGEditorFormData({
    this.history = '',
    this.rhythmRegularity = 'Regular',
    this.isSinus = true,
    this.conductionRatio = '1:1',
    this.rate = 60,
    this.prCategory = 'Normal',
    this.qrsCategory = 'Normal',
    this.qtCategory = 'Normal',
    this.avBlock = 'None',
    this.saBlock = 'None',
    this.axis = 'Normal',
    this.pWaveMorph = 'Normal',
    this.atrialEnlargement = 'None',
    this.hypertrophy = 'None',
    this.bbb = 'None',
    this.qWaves = 'None',
    this.ischemia = 'None',
    this.tWave = 'Normal',
    this.includeManagement = false,
    this.urgency = 'Routine',
    this.managementNotes = '',
  });

  static String mapMsToCategory(dynamic val, int minMs, int maxMs) {
    if (val == null) return 'Normal';
    final ms = int.tryParse(val.toString()) ?? 0;
    if (ms == 0) return 'Normal';
    if (ms < minMs) return 'Shortened';
    if (ms > maxMs) return 'Prolonged';
    return 'Normal';
  }

  factory ECGEditorFormData.fromFindings(Map<String, dynamic> f) {
    final history = f['history']?.toString() ?? '';

    String rhythmRegularity = 'Regular';
    bool isSinus = true;
    String conductionRatio = '1:1';
    if (f.containsKey('rhythm') && f['rhythm'] is Map) {
      final r = f['rhythm'] as Map;
      rhythmRegularity = r['regularity']?.toString() ?? 'Regular';
      isSinus = r['sinus'] == true;
      conductionRatio = r['p_qrs_relation']?.toString() ??
          r['conduction_ratio']?.toString() ??
          '1:1';
    } else if (f.containsKey('rhythm')) {
      rhythmRegularity = f['rhythm']?.toString() ?? 'Regular';
    }

    int rate = 60;
    if (f.containsKey('rate')) {
      if (f['rate'] is Map) {
        final r = f['rate'] as Map;
        rate = int.tryParse(r['target']?.toString() ??
                r['max']?.toString() ??
                r['min']?.toString() ??
                '60') ??
            60;
      } else {
        rate = int.tryParse(f['rate'].toString()) ?? 60;
      }
    }

    String prCategory = 'Normal';
    String qrsCategory = 'Normal';
    String qtCategory = 'Normal';
    String avBlock = 'None';
    String saBlock = 'None';
    if (f.containsKey('conduction') && f['conduction'] is Map) {
      final c = f['conduction'] as Map;
      prCategory = c['pr_category']?.toString() ??
          mapMsToCategory(c['pr_interval'], 120, 200);
      qrsCategory = c['qrs_category']?.toString() ??
          mapMsToCategory(c['qrs_duration'], 0, 120);
      qtCategory = c['qt_category']?.toString() ??
          mapMsToCategory(c['qt_interval'], 0, 440);
      avBlock = c['av_block']?.toString() ?? 'None';
      saBlock = c['sa_block']?.toString() ??
          (f['rhythm'] is Map
              ? (f['rhythm'] as Map)['sa_block']?.toString()
              : null) ??
          'None';
    } else if (f['qrs'] == 'Wide') {
      qrsCategory = 'Prolonged';
    }

    String axis = 'Normal';
    if (f.containsKey('axis')) {
      if (f['axis'] is Map) {
        final a = f['axis'] as Map;
        axis = a['quadrant']?.toString() ??
            a['deviation']?.toString() ??
            'Normal';
      } else {
        axis = f['axis']?.toString() ?? 'Normal';
      }
    }

    String pWaveMorph = 'Normal';
    String atrialEnlargement = 'None';
    if (f.containsKey('p_wave') && f['p_wave'] is Map) {
      final p = f['p_wave'] as Map;
      pWaveMorph = p['morphology']?.toString() ?? 'Normal';
      atrialEnlargement = p['atrial_enlargement']?.toString() ??
          p['enlargement']?.toString() ??
          'None';
    }

    String hypertrophy = 'None';
    String bbb = 'None';
    String qWaves = 'None';
    if (f.containsKey('qrs_morph') && f['qrs_morph'] is Map) {
      final q = f['qrs_morph'] as Map;
      hypertrophy = q['hypertrophy']?.toString() ?? 'None';
      bbb = q['bbb']?.toString() ?? 'None';
      qWaves = q['q_waves']?.toString() ?? 'None';
    } else if (f.containsKey('qrs') && f['qrs'] is Map) {
      final q = f['qrs'] as Map;
      hypertrophy = q['hypertrophy']?.toString() ?? 'None';
      bbb = q['bbb']?.toString() ?? 'None';
      qWaves = q['q_waves']?.toString() ?? 'None';
    }

    String ischemia = 'None';
    String tWave = 'Normal';
    if (f.containsKey('st_t') && f['st_t'] is Map) {
      final st = f['st_t'] as Map;
      ischemia = st['ischemia']?.toString() ?? 'None';
      tWave = st['t_wave']?.toString() ?? 'Normal';
    }

    bool includeManagement = false;
    String urgency = 'Routine';
    String managementNotes = '';
    if (f.containsKey('management') && f['management'] is Map) {
      includeManagement = true;
      final m = f['management'] as Map;
      urgency = m['urgency']?.toString() ?? 'Routine';
      managementNotes = m['notes']?.toString() ?? '';
    }

    return ECGEditorFormData(
      history: history,
      rhythmRegularity: rhythmRegularity,
      isSinus: isSinus,
      conductionRatio: conductionRatio,
      rate: rate,
      prCategory: prCategory,
      qrsCategory: qrsCategory,
      qtCategory: qtCategory,
      avBlock: avBlock,
      saBlock: saBlock,
      axis: axis,
      pWaveMorph: pWaveMorph,
      atrialEnlargement: atrialEnlargement,
      hypertrophy: hypertrophy,
      bbb: bbb,
      qWaves: qWaves,
      ischemia: ischemia,
      tWave: tWave,
      includeManagement: includeManagement,
      urgency: urgency,
      managementNotes: managementNotes,
    );
  }

  Map<String, dynamic> toFindingsJson() {
    final findings = <String, dynamic>{
      'history': history,
      'rhythm': {
        'regularity': rhythmRegularity,
        'sinus': isSinus,
        'conduction_ratio': conductionRatio,
        'p_qrs_relation': conductionRatio,
      },
      'rate': {
        'target': rate,
        'min': rate,
        'max': rate,
      },
      'conduction': {
        'pr_category': prCategory,
        'qrs_category': qrsCategory,
        'qt_category': qtCategory,
        'av_block': avBlock,
        'sa_block': saBlock,
      },
      'axis': {
        'quadrant': axis,
        'deviation': axis,
      },
      'p_wave': {
        'morphology': pWaveMorph,
        'atrial_enlargement': atrialEnlargement,
        'enlargement': atrialEnlargement,
      },
      'qrs_morph': {
        'hypertrophy': hypertrophy,
        'bbb': bbb,
        'q_waves': qWaves,
      },
      'st_t': {
        'ischemia': ischemia,
        't_wave': tWave,
      },
    };

    if (includeManagement) {
      findings['management'] = {
        'urgency': urgency,
        'notes': managementNotes,
      };
    }

    return findings;
  }
}

