import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/stats_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Dialog for managing sections (sub-topics) under a subject.
class ManageSectionsDialog extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final VoidCallback onChanged;

  const ManageSectionsDialog({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.onChanged,
  });

  @override
  State<ManageSectionsDialog> createState() => _ManageSectionsDialogState();
}

class _ManageSectionsDialogState extends State<ManageSectionsDialog> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameHuController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameHuController.dispose();
    super.dispose();
  }

  Future<void> _createSection() async {
    if (_nameEnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorSectionNameEmpty)),
      );
      return;
    }

    setState(() => _isCreating = true);
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final success = await stats.createTopic(_nameEnController.text.trim(),
        _nameHuController.text.trim(), widget.subjectId);
    setState(() => _isCreating = false);

    if (success) {
      _nameEnController.clear();
      _nameHuController.clear();
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminSuccessSectionCreated)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminErrorSectionCreateFailed)),
        );
      }
    }
  }

  Future<void> _deleteSection(int topicId, String name) async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteSectionTitle),
        content: Text(l10n.adminConfirmDeleteSection(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    String? error = await stats.deleteTopic(topicId);

    // Check for "has questions" error (409 Conflict)
    if (error != null && error.contains("question(s)")) {
      if (!mounted) return;

      final confirmForce = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.adminConfirmDataLossTitle,
              style: const TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error ?? "Unknown error",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(l10n.adminDeleteSectionWarning),
              const SizedBox(height: 12),
              Text(l10n.adminConfirmAction),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.adminYesDeleteEverything,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmForce == true) {
        error = await stats.deleteTopic(topicId, force: true);
      } else {
        return;
      }
    }

    if (error == null) {
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminSuccessSectionDeleted)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${l10n.adminManageSectionsTitle} - ${widget.subjectName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Add Section Input
            TextFormField(
              controller: _nameEnController,
              decoration:
                  CozyTheme.inputDecoration(context, l10n.adminSectionNameEnLabel),
              validator: (val) =>
                  val == null || val.isEmpty ? l10n.adminRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameHuController,
              decoration:
                  CozyTheme.inputDecoration(context, l10n.adminSectionNameHuLabel),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createSection,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add),
                label: Text(l10n.adminAddSection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary,
                  foregroundColor: CozyTheme.of(context).textInverse,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sections List
            Text(
              l10n.adminExistingSections,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<StatsProvider>(
              builder: (context, stats, _) {
                final sections = stats.topics
                    .where((t) => t['parent_id'] == widget.subjectId)
                    .toList();

                if (sections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.adminNoSectionsYet,
                        style: const TextStyle(color: Colors.grey)),
                  );
                }

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return SectionListTile(
                        section: section,
                        onDelete: () => _deleteSection(section['id'],
                            section['name_en'] ?? section['name']),
                        onRename: (nameEn, nameHu) async {
                          final error = await stats.updateTopic(
                              section['id'], nameEn, nameHu);
                          if (error == null) {
                            widget.onChanged();
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single editable section row within ManageSectionsDialog.
class SectionListTile extends StatefulWidget {
  final Map<String, dynamic> section;
  final VoidCallback onDelete;
  final Function(String, String) onRename;

  const SectionListTile({
    super.key,
    required this.section,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<SectionListTile> createState() => _SectionListTileState();
}

class _SectionListTileState extends State<SectionListTile> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  bool _isEditing = false;
  late TextEditingController _editEnController;
  late TextEditingController _editHuController;
  String _editLang = 'en';

  @override
  void initState() {
    super.initState();
    _editEnController = TextEditingController(
        text: widget.section['name_en'] ?? widget.section['name'] ?? '');
    _editHuController =
        TextEditingController(text: widget.section['name_hu'] ?? '');
  }

  @override
  void dispose() {
    _editEnController.dispose();
    _editHuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: _isEditing
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ChoiceChip(
                      label: const Text("EN"),
                      labelStyle: TextStyle(
                        color: _editLang == 'en'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'en',
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).paperWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: CozyTheme.of(context).primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'en'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU"),
                      labelStyle: TextStyle(
                        color: _editLang == 'hu'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selected: _editLang == 'hu',
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).paperWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: CozyTheme.of(context).primary),
                      ),
                      showCheckmark: false,
                      onSelected: (val) => setState(() => _editLang = 'hu'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                TextField(
                  controller:
                      _editLang == 'en' ? _editEnController : _editHuController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "${l10n.adminRenameSection} (${_editLang.toUpperCase()})",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: CozyTheme.of(context).primary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: CozyTheme.of(context).primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _isEditing = false),
                    ),
                  ),
                  onSubmitted: (val) {
                    widget.onRename(
                        _editEnController.text, _editHuController.text);
                    setState(() => _isEditing = false);
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.section['name_en'] ?? widget.section['name'] ?? ''),
                if (widget.section['name_hu'] != null &&
                    widget.section['name_hu'].isNotEmpty)
                  Text(
                    widget.section['name_hu'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
      trailing: _isEditing
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditing = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
    );
  }
}
