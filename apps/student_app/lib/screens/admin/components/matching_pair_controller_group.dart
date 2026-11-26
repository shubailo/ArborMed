import 'package:flutter/material.dart';
import '../../../core/models/admin_matching_pair.dart';

/// A group of text controllers for a matching pair question item.
/// Used by the question editor dialog for matching pair questions.
class MatchingPairControllerGroup {
  final TextEditingController leftEn;
  final TextEditingController leftHu;
  final TextEditingController rightEn;
  final TextEditingController rightHu;

  final AdminMatchingPair original;

  MatchingPairControllerGroup({
    this.original = const AdminMatchingPair(),
    required this.leftEn,
    required this.leftHu,
    required this.rightEn,
    required this.rightHu,
  });

  factory MatchingPairControllerGroup.fromPair(AdminMatchingPair pair) {
    return MatchingPairControllerGroup(
      original: pair,
      leftEn: TextEditingController(text: pair.text('left', 'en')),
      leftHu: TextEditingController(text: pair.text('left', 'hu')),
      rightEn: TextEditingController(text: pair.text('right', 'en')),
      rightHu: TextEditingController(text: pair.text('right', 'hu')),
    );
  }

  Map<String, dynamic> toJson() => original.edited(
      leftEn: leftEn.text,
      leftHu: leftHu.text,
      rightEn: rightEn.text,
      rightHu: rightHu.text);

  void dispose() {
    leftEn.dispose();
    leftHu.dispose();
    rightEn.dispose();
    rightHu.dispose();
  }
}
