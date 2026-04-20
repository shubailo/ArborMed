enum RankStatus {
  unmatched,
  intern,
  resident,
  attending,
  chief;

  String get label {
    switch (this) {
      case RankStatus.unmatched:
        return 'Unmatched Student';
      case RankStatus.intern:
        return 'Medical Intern';
      case RankStatus.resident:
        return 'Junior Resident';
      case RankStatus.attending:
        return 'Attending Physician';
      case RankStatus.chief:
        return 'Chief of Medicine';
    }
  }

  static RankStatus fromString(String? value) {
    if (value == null) return RankStatus.unmatched;
    try {
      return RankStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase() || e.toString() == value,
      );
    } catch (_) {
      return RankStatus.unmatched;
    }
  }
}
