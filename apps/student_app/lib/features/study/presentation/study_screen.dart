import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_providers.dart';
import 'study_body.dart';
import 'widgets/study_top_bar.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => ref.read(studyControllerProvider).login(),
            child: const Text('Login Default Student'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Match the screenshot's pure white bg
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const StudyTopBar(),
              ),
            ),
            const Expanded(child: StudyBody()),
          ],
        ),
      ),
    );
  }
}
