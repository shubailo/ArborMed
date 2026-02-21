class ClinicDirectoryEntryDto {
  final String userId;
  final String displayName;
  final String overallMasteryBand;
  final String? roomPreviewSeed;

  ClinicDirectoryEntryDto({
    required this.userId,
    required this.displayName,
    required this.overallMasteryBand,
    this.roomPreviewSeed,
  });

  factory ClinicDirectoryEntryDto.fromJson(Map<String, dynamic> json) {
    return ClinicDirectoryEntryDto(
      userId: json['userId'],
      displayName: json['displayName'],
      overallMasteryBand: json['overallMasteryBand'],
      roomPreviewSeed: json['roomPreviewSeed'],
    );
  }
}

class ClinicDirectoryDto {
  final String courseId;
  final List<ClinicDirectoryEntryDto> entries;

  ClinicDirectoryDto({required this.courseId, required this.entries});

  factory ClinicDirectoryDto.fromJson(Map<String, dynamic> json) {
    return ClinicDirectoryDto(
      courseId: json['courseId'],
      entries: (json['entries'] as List)
          .map((e) => ClinicDirectoryEntryDto.fromJson(e))
          .toList(),
    );
  }
}
