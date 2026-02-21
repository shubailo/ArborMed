import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/ui/cozy_button.dart';
import 'package:student_app/core/ui/cozy_icon_button.dart';
import 'package:student_app/core/ui/cozy_badge.dart';
import 'package:student_app/core/ui/cozy_modal_scaffold.dart';
import 'package:student_app/features/room/presentation/widgets/decorate_shop_modal.dart';
import 'package:student_app/features/social/presentation/widgets/clinic_directory_panel.dart';
import 'package:student_app/features/progress/presentation/providers/progress_providers.dart';
import 'package:student_app/features/study/presentation/widgets/mistake_review_intro_panel.dart';
import 'package:student_app/features/study/presentation/pages/quiz_page.dart';
import 'package:student_app/screens/progress_shell_screen.dart';
import 'package:student_app/core/audio/audio_provider.dart';

class CozyActionsOverlay extends ConsumerStatefulWidget {
  const CozyActionsOverlay({super.key});

  @override
  ConsumerState<CozyActionsOverlay> createState() => _CozyActionsOverlayState();
}

class _CozyActionsOverlayState extends ConsumerState<CozyActionsOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).playAmbient('audio/music/cool_ward_loop.mp3');
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityTrends = ref.watch(activityTrendsProvider('7d'));

    final shouldShowSmartReview = activityTrends.maybeWhen(
      data: (trends) => trends.overallAccuracy < 0.85 && trends.days.isNotEmpty,
      orElse: () => false,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CozyTheme.spacingLarge),
        child: Stack(
          children: [
            // Bottom-Left Stack: Profile (Stats) + Social (Directory)
            Positioned(
              left: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CozyIconButton(
                    icon: Icons.people_outline,
                    onTap: () => _openClinicDirectory(context),
                  ),
                  const SizedBox(height: 12),
                  CozyIconButton(
                    icon: Icons.bar_chart_outlined,
                    onTap: () => _openProfile(context),
                  ),
                ],
              ),
            ),

            // Bottom-Center: Primary Study Actions
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shouldShowSmartReview) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CozyButton(
                            label: 'Smart Review',
                            icon: Icons.auto_awesome,
                            color: const Color(0xFFE06C53),
                            onTap: () => _openSmartReview(context),
                          ),
                          const Positioned(
                            top: -8,
                            right: -8,
                            child: CozyBadge(label: 'Recommended', color: AppTheme.softClay),
                          ),
                        ],
                      ),
                    ),
                  ],
                  CozyButton(
                    label: 'Study',
                    icon: Icons.history_edu_outlined,
                    large: true,
                    onTap: () => _openQuizPortal(context),
                  ),
                ],
              ),
            ),

            // Bottom-Right Stack: Settings + Decorate
            Positioned(
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CozyIconButton(
                    icon: Icons.brush_outlined,
                    onTap: () => _openDecorateMenu(context),
                  ),
                  const SizedBox(height: 12),
                  CozyIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => _openSettings(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuizPortal(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CozyModalScaffold(
        title: 'Quiz Portal',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CozyButton(
            label: 'Start Study Session',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizPage()),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openDecorateMenu(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DecorateShopModal(),
    );
  }

  void _openProfile(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressShellScreen()),
    );
  }

  void _openClinicDirectory(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClinicDirectoryPanel(courseId: 'default_course'),
    );
  }

  void _openSmartReview(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MistakeReviewIntroPanel(),
    );
  }

  void _openSettings(BuildContext context) {
    ref.read(audioManagerProvider).playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsPanel(),
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(audioSettingsProvider);

    return CozyModalScaffold(
      title: 'Settings',
      child: Column(
        children: [
          ListTile(
            leading: Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: AppTheme.warmBrown),
            title: const Text('Mute Audio'),
            trailing: Switch(
              value: isMuted,
              onChanged: (value) {
                ref.read(audioSettingsProvider.notifier).toggleMute();
                ref.read(audioManagerProvider).playClick();
              },
            ),
          ),
        ],
      ),
    );
  }
}
