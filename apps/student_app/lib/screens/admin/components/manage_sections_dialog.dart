import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/cozy_theme.dart';

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
  final _en = TextEditingController();
  final _hu = TextEditingController();
  late final _provider = context.read<TopicProvider>();
  late final int _session;
  bool _busy = false;

  AppLocalizations get labels => AppLocalizations.of(context)!;
  bool get _active =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      _provider.sessionRevision == _session;

  @override
  void initState() {
    super.initState();
    _session = _provider.sessionRevision;
  }

  @override
  void dispose() {
    _en.dispose();
    _hu.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _run(Future<bool> Function() operation) async {
    if (_busy || !_active) return false;
    setState(() => _busy = true);
    try {
      final changed = await operation();
      if (!_active || !changed) return false;
      widget.onChanged();
      return true;
    } on ApiException catch (error) {
      if (_active) _message(error.message);
    } catch (error) {
      debugPrint('Section operation failed (${error.runtimeType}).');
      if (_active) _message(labels.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return false;
  }

  Future<void> _create() async {
    await _run(() async {
      if (_en.text.trim().isEmpty) {
        _message(labels.adminErrorSectionNameEmpty);
        return false;
      }
      await _provider.createTopic(_en.text, _hu.text, widget.subjectId);
      if (!_active) return false;
      _en.clear();
      _hu.clear();
      _message(labels.adminSuccessSectionCreated);
      return true;
    });
  }

  Future<bool> _confirm(String name,
      [TopicDeleteConfirmation? questions]) async {
    final l = labels;
    return await showDialog<bool>(
          context: context,
          builder: (dialog) {
            void finish(bool value) {
              if (ModalRoute.of(dialog)?.isCurrent == true) {
                Navigator.pop(dialog, value);
              }
            }

            return AlertDialog(
              scrollable: true,
              title: Text(questions == null
                  ? l.adminDeleteSectionTitle
                  : l.adminConfirmDataLossTitle),
              content: Text(questions == null
                  ? l.adminConfirmDeleteSection(name)
                  : '$name (${questions.count})\n\n${l.adminDeleteSectionWarning}'),
              actions: [
                TextButton(
                    onPressed: () => finish(false), child: Text(l.cancel)),
                TextButton(
                    onPressed: () => finish(true),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(dialog).colorScheme.error),
                    child: Text(questions == null
                        ? l.delete
                        : l.adminYesDeleteEverything)),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _delete(int id, String name) async {
    await _run(() async {
      if (!await _confirm(name) || !_active) return false;
      var confirmation = await _provider.deleteTopic(id);
      while (confirmation != null) {
        if (!_active || !await _confirm(name, confirmation) || !_active) {
          return false;
        }
        confirmation =
            await _provider.deleteTopic(id, confirmation: confirmation.version);
      }
      if (!_active) return false;
      _message(labels.adminSuccessSectionDeleted);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TopicProvider>();
    final enabled = !_busy && _session == provider.sessionRevision;
    final sections = provider.topics
        .where((t) => t['parent_id'] == widget.subjectId)
        .toList();
    final indices = {
      for (var i = 0; i < sections.length; i++) sections[i]['id']: i + 1
    };
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
              child: ListView.builder(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            itemCount: sections.length + 1,
            findChildIndexCallback: (key) =>
                key is ValueKey<int> ? indices[key.value] : null,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          '${labels.adminManageSectionsTitle} - ${widget.subjectName}',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _en,
                          enabled: enabled,
                          textInputAction: TextInputAction.next,
                          decoration: CozyTheme.inputDecoration(
                              context, labels.adminSectionNameEnLabel)),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _hu,
                          enabled: enabled,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _create(),
                          decoration: CozyTheme.inputDecoration(
                              context, labels.adminSectionNameHuLabel)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                              onPressed: enabled ? _create : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      CozyTheme.of(context).primary,
                                  foregroundColor:
                                      CozyTheme.of(context).textInverse),
                              icon: const Icon(Icons.add),
                              label: Text(labels.adminAddSection))),
                      const SizedBox(height: 16),
                      Text(labels.adminExistingSections,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (_busy || provider.loading)
                        const LinearProgressIndicator(),
                      if (provider.loadFailed)
                        TextButton.icon(
                            onPressed: enabled ? provider.fetchTopics : null,
                            icon: const Icon(Icons.refresh),
                            label: Text('${labels.error} · ${labels.retry}'))
                      else if (!provider.loading && sections.isEmpty)
                        Text(labels.adminNoSectionsYet),
                    ]);
              }
              final section = sections[index - 1];
              final id = section['id'] as int;
              final en = section['name_en'] as String;
              final hu = section['name_hu'] as String;
              final displayName =
                  Localizations.localeOf(context).languageCode == 'hu' &&
                          hu.isNotEmpty
                      ? hu
                      : en;
              return SectionListTile(
                key: ValueKey(id),
                nameEn: en,
                nameHu: hu,
                enabled: enabled,
                onDelete: () => _delete(id, displayName),
                onRename: (en, hu) => _run(() async {
                  if (en.trim().isEmpty) {
                    _message(labels.adminErrorSectionNameEmpty);
                    return false;
                  }
                  await provider.updateTopic(id, en, hu);
                  return true;
                }),
              );
            },
          )),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () {
                    if (ModalRoute.of(context)?.isCurrent == true) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(labels.close))),
        ]),
      ),
    );
  }
}

class SectionListTile extends StatefulWidget {
  final String nameEn, nameHu;
  final bool enabled;
  final VoidCallback onDelete;
  final Future<bool> Function(String, String) onRename;
  const SectionListTile(
      {super.key,
      required this.nameEn,
      required this.nameHu,
      required this.enabled,
      required this.onDelete,
      required this.onRename});

  @override
  State<SectionListTile> createState() => _SectionListTileState();
}

class _SectionListTileState extends State<SectionListTile> {
  final _en = TextEditingController();
  final _hu = TextEditingController();
  bool _editing = false;
  bool _hungarian = false;

  @override
  void dispose() {
    _en.dispose();
    _hu.dispose();
    super.dispose();
  }

  void _edit() {
    _en.text = widget.nameEn;
    _hu.text = widget.nameHu;
    setState(() {
      _editing = true;
      _hungarian = false;
    });
  }

  Future<void> _save() async {
    if (await widget.onRename(_en.text, _hu.text) && mounted) {
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!_editing) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.folder_outlined),
        title: Text(widget.nameEn),
        subtitle: widget.nameHu.isEmpty ? null : Text(widget.nameHu),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: widget.enabled ? _edit : null,
              tooltip: l.edit,
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: widget.enabled ? widget.onDelete : null,
              tooltip: l.delete,
              icon: const Icon(Icons.delete)),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, children: [
        for (final hu in [false, true])
          ChoiceChip(
              label: Text(hu ? 'HU' : 'EN'),
              selected: hu == _hungarian,
              onSelected: widget.enabled
                  ? (_) => setState(() => _hungarian = hu)
                  : null),
      ]),
      TextField(
          controller: _hungarian ? _hu : _en,
          enabled: widget.enabled,
          autofocus: true,
          decoration: InputDecoration(
              labelText:
                  '${l.adminRenameSection} (${_hungarian ? 'HU' : 'EN'})'),
          onSubmitted: (_) => _save()),
      Wrap(children: [
        TextButton(
            onPressed:
                widget.enabled ? () => setState(() => _editing = false) : null,
            child: Text(l.cancel)),
        TextButton(
            onPressed: widget.enabled ? _save : null, child: Text(l.save)),
      ]),
    ]);
  }
}
