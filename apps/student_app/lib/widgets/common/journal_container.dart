import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/cozy_theme.dart';
import '../../services/audio_provider.dart';

class JournalContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClose;

  const JournalContainer({
    super.key,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        height: 560,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            // 📚 Leather Binding (Left)
            Container(
              width: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF4E342E), // Leather Brown
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // 📄 Paper Pages (Right)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).background,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                      child: child,
                    ),

                    // Close Button (Sticker/Stamp style)
                    if (onClose != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Tooltip(
                          message: MaterialLocalizations.of(context).closeButtonTooltip,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Provider.of<AudioProvider>(context, listen: false).playSfx('pop');
                              if (onClose != null) onClose!();
                            },
                            child: Icon(
                              Icons.cancel_rounded,
                              color: CozyTheme.of(context)
                                  .textSecondary
                                  .withValues(alpha: 0.5),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 📑 Pages Edge Effect
            Container(
              width: 8,
              decoration: BoxDecoration(
                  color: CozyTheme.of(context).paperCream,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
