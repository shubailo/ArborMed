import 'package:flutter/material.dart';

/// A group of text controllers for a matching pair question item.
/// Used by the question editor dialog for matching pair questions.
class MatchingPairControllerGroup {
  final TextEditingController leftEn;
  final TextEditingController leftHu;
  final TextEditingController rightEn;
  final TextEditingController rightHu;

  MatchingPairControllerGroup({
    required this.leftEn,
    required this.leftHu,
    required this.rightEn,
    required this.rightHu,
  });

  void dispose() {
    leftEn.dispose();
    leftHu.dispose();
    rightEn.dispose();
    rightHu.dispose();
  }
}
