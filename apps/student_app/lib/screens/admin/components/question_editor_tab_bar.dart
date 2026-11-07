import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class QuestionEditorTabBar extends StatelessWidget {
  final TabController controller;
  final bool isTranslating;
  final VoidCallback onAutoFill;

  const QuestionEditorTabBar({
    super.key,
    required this.controller,
    required this.isTranslating,
    required this.onAutoFill,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: controller,
                labelColor: CozyTheme.of(context).primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: CozyTheme.of(context).paperWhite,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(child: Text(AppLocalizations.of(context)!.adminEnglish)),
                  Tab(child: Text(AppLocalizations.of(context)!.adminHungarian)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: isTranslating ? null : onAutoFill,
              icon: isTranslating
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                AppLocalizations.of(context)!.adminAutoFill,
                style: const TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: CozyTheme.of(context, listen: false).primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

