import 'package:flutter/material.dart';
import '../../../services/admin_question_provider.dart';

/// Keep at most one question-bank action open per provider and login.
final _activeActions = Expando<Object>('question bank dialog');

Future<void> runQuestionAction(
    BuildContext context,
    AdminQuestionProvider provider,
    Future<void> Function(bool Function() active) action) async {
  final session = provider.actionSession;
  if (_activeActions[provider] == session) return;
  _activeActions[provider] = session;
  final origin = ModalRoute.of(context);
  bool active() =>
      context.mounted &&
      origin?.isActive == true &&
      provider.actionSession == session;
  try {
    if (active()) await action(active);
  } finally {
    if (_activeActions[provider] == session) _activeActions[provider] = null;
  }
}
