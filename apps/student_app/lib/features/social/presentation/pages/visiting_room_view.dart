import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/features/social/presentation/providers/social_providers.dart';
import 'package:student_app/features/room/presentation/widgets/room_layout.dart' as widgets;
import 'package:student_app/features/room/presentation/widgets/bean_avatar_widget.dart';

class VisitingRoomView extends ConsumerWidget {
  final String userId;
  final String courseId;

  const VisitingRoomView({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We pass both userId and courseId to the provider
    final roomState = ref.watch(
      visitRoomProvider((userId: userId, courseId: courseId)),
    );

    return Scaffold(
      backgroundColor: AppTheme.ivoryCream,
      body: roomState.when(
        data: (room) {
          // Wrap with WillPopScope to ensure proper back navigation
          return Stack(
            children: [
              // The main read-only room layout
              widgets.RoomLayout(
                activeItems: room.roomItems,
                // Passing a dummy/empty callback ensures it doesn't trigger state changes locally
                onSlotTap: (slotName) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot modify another student\'s room.')),
                  );
                },
              ),

              // Top HUD for Visitors
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(CozyTheme.spacingLarge),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: CozyTheme.cardShadow,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.sageGreen,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                      const Spacer(),

                      // Visitor Info Pill
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: CozyTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            BeanAvatarWidget(
                              size: 40,
                              mood: room.bean.mood == 'happy'
                                  ? BeanMood.happy
                                  : BeanMood.focused,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Visiting ${room.displayName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.warmBrown,
                                  ),
                                ),
                                Text(
                                  room.overallMasteryBand,
                                  style: TextStyle(
                                    color: AppTheme.sageGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sageGreen),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                "Could not load room",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
