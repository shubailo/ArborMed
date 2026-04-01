import 'dart:convert';
import 'package:meta/meta.dart';

@immutable
class ECGDiagnosis {
  final int id;
  final String code;
  final String nameEn;
  final String nameHu;
  final Map<String, dynamic>? standardFindings;

  const ECGDiagnosis({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameHu,
    this.standardFindings,
  });

  factory ECGDiagnosis.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
    
    final findingsRaw = json['standard_findings_json'];
    Map<String, dynamic>? findings;
    
    if (findingsRaw != null) {
      if (findingsRaw is String && findingsRaw.isNotEmpty) {
        findings = jsonDecode(findingsRaw) as Map<String, dynamic>;
      } else if (findingsRaw is Map<String, dynamic>) {
        findings = findingsRaw;
      }
    }

    return ECGDiagnosis(
      id: safeInt(json['id']),
      code: json['code'] ?? '?',
      nameEn: json['name_en'] ?? 'Unknown',
      nameHu: json['name_hu'] ?? '',
      standardFindings: findings,
    );
  }
}
