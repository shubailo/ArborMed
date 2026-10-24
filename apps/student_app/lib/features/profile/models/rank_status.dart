import 'package:flutter/material.dart';

enum RankStatus {
  unmatched,
  intern,
  resident,
  chief,
  attending;

  String get label {
    switch (this) {
      case RankStatus.unmatched:
        return 'Medical Student';
      case RankStatus.intern:
        return 'Medical Intern';
      case RankStatus.resident:
        return 'Junior Resident';
      case RankStatus.chief:
        return 'Chief Resident';
      case RankStatus.attending:
        return 'Attending Physician';
    }
  }

  String get labelHu {
    switch (this) {
      case RankStatus.unmatched:
        return 'Orvostanhallgató';
      case RankStatus.intern:
        return 'Kórházi Gyakornok';
      case RankStatus.resident:
        return 'Rezidensorvos';
      case RankStatus.chief:
        return 'Főorvos';
      case RankStatus.attending:
        return 'Klinikai Szakorvos';
    }
  }

  IconData get icon {
    switch (this) {
      case RankStatus.unmatched:
        return Icons.school_rounded;
      case RankStatus.intern:
        return Icons.badge_rounded;
      case RankStatus.resident:
        return Icons.medical_services_rounded;
      case RankStatus.chief:
        return Icons.stars_rounded;
      case RankStatus.attending:
        return Icons.workspace_premium_rounded;
    }
  }

  static RankStatus fromString(String? value) {
    if (value == null) return RankStatus.unmatched;
    try {
      final clean = value.toLowerCase().trim();
      return RankStatus.values.firstWhere(
        (e) => e.name == clean || e.toString() == value,
      );
    } catch (_) {
      return RankStatus.unmatched;
    }
  }
}
