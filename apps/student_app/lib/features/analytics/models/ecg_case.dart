class ECGCase {
  final int id;
  final int diagnosisId;
  final String imageUrl;
  final String difficulty;
  final Map<String, dynamic> findings;
  final String? diagnosisCode;
  final String? diagnosisName;
  final String? diagnosisNameHu;

  String localizedDiagnosisName(String language) {
    final hu = diagnosisNameHu;
    return language == 'hu' && hu != null && hu.isNotEmpty ? hu : diagnosisName ?? '';
  }
  final List<int> secondaryDiagnosesIds;

  ECGCase({
    required this.id,
    required this.diagnosisId,
    required this.imageUrl,
    required this.difficulty,
    required this.findings,
    this.diagnosisCode,
    this.diagnosisName,
    this.diagnosisNameHu,
    this.secondaryDiagnosesIds = const [],
  });

  factory ECGCase.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

    return ECGCase(
      id: safeInt(json['id']),
      diagnosisId: safeInt(json['diagnosis_id']),
      imageUrl: json['image_url'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      findings: json['findings_json'] ?? {},
      diagnosisCode: json['diagnosis_code'],
      diagnosisName: json['diagnosis_name'],
      diagnosisNameHu: json['diagnosis_name_hu'],
      secondaryDiagnosesIds: (json['secondary_diagnoses_ids'] as List?)
              ?.map((e) => safeInt(e))
              .where((id) => id > 0)
              .toList() ??
          [],
    );
  }
}
