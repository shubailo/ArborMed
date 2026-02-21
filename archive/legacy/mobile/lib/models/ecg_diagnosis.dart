import 'dart:convert';

class ECGDiagnosis {
  final int id;
  final String code;
  final String nameEn;
  final String nameHu;
  final Map<String, dynamic>? standardFindings;

  ECGDiagnosis({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameHu,
    this.standardFindings,
  });

  factory ECGDiagnosis.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
    
    return ECGDiagnosis(
      id: safeInt(json['id']),
      code: json['code'] ?? '?',
      nameEn: json['name_en'] ?? 'Unknown',
      nameHu: json['name_hu'] ?? '',
      standardFindings: json['standard_findings_json'] != null
          ? (json['standard_findings_json'] is String
              ? jsonDecode(json['standard_findings_json'])
              : json['standard_findings_json'])
          : null,
    );
  }
}
