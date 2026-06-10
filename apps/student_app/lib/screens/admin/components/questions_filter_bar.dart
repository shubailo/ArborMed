import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';

class QuestionsFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedType;
  final int? selectedBloom;
  final int? selectedTopicId;
  final int? currentSubjectId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int?> onBloomChanged;
  final ValueChanged<int?> onTopicChanged;
  final VoidCallback onManageSections;
  final VoidCallback onBatchUpload;
  final VoidCallback onNewItem;

  const QuestionsFilterBar({
    super.key,
    required this.searchController,
    required this.selectedType,
    required this.selectedBloom,
    required this.selectedTopicId,
    required this.currentSubjectId,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onBloomChanged,
    required this.onTopicChanged,
    required this.onManageSections,
    required this.onBatchUpload,
    required this.onNewItem,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // 1. Search Bar
            Container(
              width: 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.adminSearchQuestions,
                  hintStyle: GoogleFonts.quicksand(
                    color: palette.textSecondary.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(Icons.search, color: palette.primary),
                  fillColor: palette.paperWhite,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Type Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              width: 150,
              decoration: BoxDecoration(
                color: palette.paperWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  hint: Text(l10n.adminAllTypes),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l10n.adminAllTypes)),
                    DropdownMenuItem(value: 'single_choice', child: Text(l10n.quizTypeSingleChoice)),
                    DropdownMenuItem(value: 'multiple_choice', child: Text(l10n.quizTypeMultipleChoice)),
                    DropdownMenuItem(value: 'true_false', child: Text(l10n.quizTypeTrueFalse)),
                    DropdownMenuItem(value: 'matching', child: Text(l10n.quizTypeMatching)),
                    DropdownMenuItem(value: 'relation_analysis', child: Text(l10n.quizTypeRelational)),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 3. Bloom Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              width: 130,
              decoration: BoxDecoration(
                color: palette.paperWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedBloom,
                  isExpanded: true,
                  hint: Text(
                    l10n.adminLevel,
                    style: GoogleFonts.quicksand(fontSize: 13),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.adminAllLevels)),
                    ...[1, 2, 3, 4].map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text("${l10n.adminLevel} $l"),
                      ),
                    ),
                  ],
                  onChanged: onBloomChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 4. Topic Filter
            if (currentSubjectId != null)
              Consumer<StatsProvider>(
                builder: (context, stats, _) {
                  final subjectSections = stats.topics.where((topic) {
                    return topic['parent_id'] == currentSubjectId;
                  }).toList();

                  // We remove the setState logic from here and rely on the parent or provider to manage invalid topics.
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(maxWidth: 240),
                    decoration: BoxDecoration(
                      color: palette.paperWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.textSecondary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedTopicId,
                        isExpanded: true,
                        hint: Text(
                          l10n.adminAllSections,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(fontSize: 13),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.adminAllSections),
                          ),
                          ...subjectSections.map(
                            (topic) => DropdownMenuItem(
                              value: topic['id'] as int,
                              child: Text(
                                (AppLocalizations.of(context)!.localeName == 'hu'
                                        ? topic['name_hu']
                                        : topic['name_en'])?.toString() ??
                                    topic['name']?.toString() ??
                                    l10n.adminUnnamedSection,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.quicksand(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: onTopicChanged,
                      ),
                    ),
                  );
                },
              ),
            if (currentSubjectId != null) const SizedBox(width: 8),
            if (currentSubjectId != null)
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                tooltip: l10n.adminManageSectionsTooltip,
                onPressed: onManageSections,
                style: IconButton.styleFrom(
                  backgroundColor: palette.paperWhite,
                  foregroundColor: palette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: palette.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ),
            const SizedBox(width: 16),

            // 5. Actions
            IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: l10n.adminBatchUploadTooltip,
              onPressed: onBatchUpload,
              style: IconButton.styleFrom(
                backgroundColor: palette.paperWhite,
                foregroundColor: palette.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onNewItem,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                selectedType == 'ecg' ? l10n.adminNewECG : l10n.adminNewQuestion,
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.textInverse,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
