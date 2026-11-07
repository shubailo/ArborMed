import 'package:flutter/material.dart';
import '../../../theme/cozy_theme.dart';

/// Step progress indicators for the ECG practice wizard.
class EcgWizardProgress extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasHistory;

  const EcgWizardProgress({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasHistory,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: palette.textSecondary.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < totalPages; i++) ...[
            _buildStepCircle(i, palette),
            if (i < totalPages - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i < currentPage
                      ? palette.primary
                      : palette.textSecondary.withValues(alpha: 0.1),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, CozyPalette palette) {
    final isActive = index <= currentPage;
    final isCurrent = index == currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrent
            ? palette.primary
            : (isActive
                ? palette.primary.withValues(alpha: 0.2)
                : palette.surface),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? palette.primary
              : palette.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: isActive && !isCurrent
            ? Icon(Icons.check, size: 16, color: palette.primary)
            : Text(
                "${index + (hasHistory ? 0 : 1)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? palette.textInverse
                      : palette.textSecondary,
                ),
              ),
      ),
    );
  }
}

/// Navigation toolbar (Back / Next / Submit buttons) for the ECG wizard.
class EcgWizardNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const EcgWizardNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final isLastPage = currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        boxShadow: [
          BoxShadow(
            color: palette.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: palette.primary),
                ),
                child: Text(
                  isHu ? "VISSZA" : "BACK",
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastPage ? onSubmit : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.textInverse,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLastPage
                    ? (isHu ? "ELEMZÉS BEKÜLDÉSE" : "SUBMIT ANALYSIS")
                    : (isHu ? "KÖVETKEZŐ LÉPÉS" : "NEXT STEP"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
