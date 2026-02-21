import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/ui/cozy_modal_scaffold.dart';
import 'package:student_app/features/social/presentation/providers/social_providers.dart';
import 'package:student_app/features/social/presentation/pages/visiting_room_view.dart';
import 'package:student_app/features/room/presentation/widgets/bean_avatar_widget.dart';

class ClinicDirectoryPanel extends ConsumerWidget {
  final String courseId;

  const ClinicDirectoryPanel({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryState = ref.watch(clinicDirectoryProvider(courseId));

    return CozyModalScaffold(
      title: 'Clinic Directory',
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: directoryState.when(
          data: (data) {
            final entries = data.entries;
            if (entries.isEmpty) {
              return const Center(child: Text("No other students found yet."));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: CozyTheme.spacingMedium,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _DirectoryCard(
                  entry: entry,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitingRoomView(
                          userId: entry.userId,
                          courseId: courseId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.sageGreen),
          ),
          error: (err, _) => Center(
            child: Text(
              "Error: $err",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final dynamic entry;
  final VoidCallback onTap;

  const _DirectoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine color/mood based on mastery band
    Color bandColor = AppTheme.softClay;
    String label = "Learner";
    BeanMood mood = BeanMood.focused;

    switch (entry.overallMasteryBand) {
      case 'ADVANCED':
        bandColor = AppTheme.sageGreen;
        label = "Advanced";
        mood = BeanMood.happy;
        break;
      case 'CONFIDENT':
        bandColor = Colors.teal.shade300;
        label = "Confident";
        mood = BeanMood.happy;
        break;
      case 'GROWING':
        bandColor = AppTheme.warmBrown.withValues(alpha: 0.5);
        label = "Growing";
        mood = BeanMood.idle;
        break;
      case 'EARLY':
      default:
        bandColor = AppTheme.softClay;
        label = "Early Days";
        mood = BeanMood.idle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: CozyTheme.spacingSmall),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: CozyTheme.borderMedium,
        side: BorderSide(color: AppTheme.sageGreen.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: BeanAvatarWidget(size: 40, mood: mood),
        title: Text(
          entry.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.warmBrown,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bandColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.warmBrown.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.sageGreen),
      ),
    );
  }
}
