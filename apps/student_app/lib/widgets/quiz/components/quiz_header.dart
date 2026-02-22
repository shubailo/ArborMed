import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../services/auth_provider.dart';
import '../../../../widgets/cozy/cozy_progress_bar.dart';
import '../../../services/quiz_controller.dart';

class QuizHeader extends StatelessWidget {
  final VoidCallback onClose;
  final PulseNotifier progressPulseNotifier;

  const QuizHeader({
    super.key,
    required this.onClose,
    required this.progressPulseNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    final totalCoins = user?.coins ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🏁 Integrated Motivational Hub
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: palette.paperWhite.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: palette.textPrimary.withValues(alpha: 0.05))),
                    child: Row(
                      children: [
                        Image.asset('assets/ui/buttons/stethoscope_hud.png',
                            width: 18, height: 18),
                        const SizedBox(width: 6),
                        Text("$totalCoins",
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: palette.secondary)),
                      ],
                    ),
                  ),
                ],
              ),

              // Minimal Close
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close_rounded,
                    size: 24,
                    color: palette.textSecondary.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Slimmer, Sleeker Progress
          Consumer<QuizController>(
            builder: (context, controller, _) {
              final levelProgress = controller.state.levelProgress;
              
              return Column(
                children: [
                   Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: CozyProgressBar(
                          current: (levelProgress * 100).toInt(),
                          total: 100,
                          height: 10,
                          pulseNotifier: progressPulseNotifier,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Level Progress",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: palette.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                      Text(
                        "${(levelProgress * 20).round()} / 20",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
