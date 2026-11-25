import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/features/analytics/models/quote.dart';
import '../../../services/admin_content_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../../../widgets/admin/dual_language_field.dart';
import '../../../widgets/admin/quote_preview_card.dart';
import '../../../widgets/admin/icon_picker_dialog.dart';
import '../../../widgets/admin/icon_manager_dialog.dart';
import '../../../services/api_service.dart';
import '../../../generated/l10n/app_localizations.dart';

class QuoteEditorDialog extends StatefulWidget {
  final Quote? quote;

  const QuoteEditorDialog({super.key, this.quote});

  @override
  State<QuoteEditorDialog> createState() => _QuoteEditorDialogState();
}

class _QuoteEditorDialogState extends State<QuoteEditorDialog> {
  late TextEditingController _textEnController;
  late TextEditingController _textHuController;
  late TextEditingController _authorController;
  late TextEditingController _titleEnController;
  late TextEditingController _titleHuController;

  String _currentLang = 'en';
  late String _selectedIcon;
  bool _isTranslating = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textEnController = TextEditingController(text: widget.quote?.textEn ?? '');
    _textHuController = TextEditingController(text: widget.quote?.textHu ?? '');
    _authorController = TextEditingController(text: widget.quote?.author ?? '');
    _titleEnController = TextEditingController(text: widget.quote?.titleEn ?? 'Study Break');
    _titleHuController = TextEditingController(text: widget.quote?.titleHu ?? 'Tanulás');
    
    if (widget.quote != null) {
      _selectedIcon = (widget.quote!.customIconUrl != null && widget.quote!.customIconUrl!.isNotEmpty)
          ? widget.quote!.customIconUrl!
          : widget.quote!.iconName;
    } else {
      _selectedIcon = 'menu_book_rounded';
    }
  }

  @override
  void dispose() {
    _textEnController.dispose();
    _textHuController.dispose();
    _authorController.dispose();
    _titleEnController.dispose();
    _titleHuController.dispose();
    super.dispose();
  }

  void _openIconManager({bool isSelectionMode = false, Function(String)? onSelected}) {
    showDialog(
      context: context,
      builder: (context) => IconManagerDialog(
        isSelectionMode: isSelectionMode,
        onIconSelected: onSelected,
      ),
    );
  }

  Future<void> _translateField(TextEditingController en, TextEditingController hu) async {
    if (_isTranslating || _isSaving) return;
    final sourceController = _currentLang == 'en' ? hu : en;
    final targetController = _currentLang == 'en' ? en : hu;
    final sourceText = sourceController.text;
    final targetText = targetController.text;
    final sourceLang = _currentLang == 'en' ? 'hu' : 'en';
    final targetLang = _currentLang;

    if (sourceText.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.adminSourceFieldEmpty);
      return;
    }

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    final translated = await Provider.of<AdminContentProvider>(context, listen: false)
        .translateText(sourceText, sourceLang, targetLang);
    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      if (translated == null || translated.isEmpty) {
        _error = AppLocalizations.of(context)!.translationFailed;
      } else if (sourceController.text == sourceText && targetController.text == targetText) {
        targetController.text = translated;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || _isTranslating) return;
    final labels = AppLocalizations.of(context)!;
    final en = _textEnController.text.trim();
    if (en.isEmpty) {
      setState(() {
        _currentLang = 'en';
        _error = '${labels.adminQuoteTextLabel} (EN) — ${labels.adminRequired}';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final provider = context.read<AdminContentProvider>();
    final hu = _textHuController.text.trim();
    final author = _authorController.text.trim();
    final titleEn = _titleEnController.text.trim();
    final titleHu = _titleHuController.text.trim();
    final random = _selectedIcon == 'random_gallery';
    final custom = _selectedIcon.startsWith('/') || _selectedIcon.startsWith('http');
    final name = random ? 'random' : custom ? 'custom' : _selectedIcon;
    final url = random || custom ? _selectedIcon : null;
    final id = widget.quote?.id;
    final success = id == null
        ? await provider.createQuote(en, hu, author, titleEn: titleEn, titleHu: titleHu, iconName: name, customIconUrl: url)
        : await provider.updateQuote(id, en, hu, author, titleEn: titleEn, titleHu: titleHu, iconName: name, customIconUrl: url);
    if (!mounted) return;
    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      if (id != null) messenger.showSnackBar(SnackBar(content: Text(labels.adminQuoteUpdated)));
    } else {
      setState(() {
        _isSaving = false;
        _error = labels.adminQuoteSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.quote == null ? AppLocalizations.of(context)!.adminAddQuote : AppLocalizations.of(context)!.adminEditQuote,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          ),
          Row(
            children: [
              ChoiceChip(
                label: const Text("EN", style: TextStyle(fontWeight: FontWeight.w600)),
                selected: _currentLang == 'en',
                onSelected: (val) => setState(() => _currentLang = 'en'),
                selectedColor: CozyTheme.of(context).primary,
                backgroundColor: CozyTheme.of(context).surface,
                labelStyle: TextStyle(
                  color: _currentLang == 'en'
                      ? CozyTheme.of(context).textInverse
                      : CozyTheme.of(context).textSecondary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("HU", style: TextStyle(fontWeight: FontWeight.w600)),
                selected: _currentLang == 'hu',
                onSelected: (val) => setState(() => _currentLang = 'hu'),
                selectedColor: CozyTheme.of(context).primary,
                backgroundColor: CozyTheme.of(context).surface,
                labelStyle: TextStyle(
                  color: _currentLang == 'hu'
                      ? CozyTheme.of(context).textInverse
                      : CozyTheme.of(context).textSecondary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuotePreviewCard(
                text: _currentLang == 'en' ? _textEnController.text : _textHuController.text,
                author: _authorController.text,
                title: _currentLang == 'en' ? _titleEnController.text : _titleHuController.text,
                iconName: _selectedIcon,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: CozyTheme.of(context).paperWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]),
                    child: (_selectedIcon == 'random_gallery')
                        ? Icon(Icons.shuffle_rounded,
                            color: CozyTheme.of(context).accent, size: 24)
                        : (_selectedIcon.startsWith('/') || _selectedIcon.startsWith('http'))
                            ? ClipOval(
                                child: Image.network(
                                  '${ApiService.baseUrl}$_selectedIcon',
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.broken_image,
                                      size: 24,
                                      color: Colors.grey),
                                ),
                              )
                            : Icon(
                                IconPickerDialog.getIconData(_selectedIcon),
                                color: CozyTheme.of(context).primary,
                                size: 24,
                              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: Icon(Icons.grid_view,
                              size: 16,
                              color: CozyTheme.of(context).textInverse),
                          label: Text(AppLocalizations.of(context)!.adminQuoteGallery,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CozyTheme.of(context).textInverse)),
                          backgroundColor: CozyTheme.of(context).primary,
                          onPressed: () {
                            _openIconManager(
                              isSelectionMode: true,
                              onSelected: (newIcon) {
                                setState(() => _selectedIcon = newIcon);
                              },
                            );
                          },
                        ),
                        ActionChip(
                          avatar: Icon(Icons.shuffle,
                              size: 16,
                              color: CozyTheme.of(context).textInverse),
                          label: Text(AppLocalizations.of(context)!.adminQuoteRandom,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CozyTheme.of(context).textInverse)),
                          backgroundColor: CozyTheme.of(context).accent,
                          onPressed: () => setState(() => _selectedIcon = 'random_gallery'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DualLanguageField(
                controllerEn: _titleEnController,
                controllerHu: _titleHuController,
                label: AppLocalizations.of(context)!.adminQuoteTitleLabel,
                currentLanguage: _currentLang,
                isMultiLine: false,
                onTranslate: () => _translateField(_titleEnController, _titleHuController),
                isTranslating: _isTranslating,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 24),
              DualLanguageField(
                controllerEn: _textEnController,
                controllerHu: _textHuController,
                label: AppLocalizations.of(context)!.adminQuoteTextLabel,
                currentLanguage: _currentLang,
                isMultiLine: true,
                onTranslate: () => _translateField(_textEnController, _textHuController),
                isTranslating: _isTranslating,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: CozyTheme.inputDecoration(context, AppLocalizations.of(context)!.adminAuthorOptional),
                onChanged: (val) => setState(() {}),
              ),
              if (_error != null) Semantics(
                container: true,
                liveRegion: true,
                child: Text(_error!, style: TextStyle(color: CozyTheme.of(context).error)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _isTranslating || _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: CozyTheme.of(context).primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: widget.quote != null ? Icon(Icons.check, color: CozyTheme.of(context).textInverse) : null,
          label: Text(
            widget.quote == null ? AppLocalizations.of(context)!.adminAddQuote : AppLocalizations.of(context)!.save,
            style: const TextStyle(color: Colors.white)
          ),
        ),
      ],
    );
  }
}

