import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/admin/dual_language_field.dart';
import '../../widgets/admin/quote_preview_card.dart';
import '../../widgets/admin/icon_picker_dialog.dart';
import '../../widgets/admin/icon_manager_dialog.dart';
import '../../services/api_service.dart';
import '../../generated/l10n/app_localizations.dart';

class AdminQuotesScreen extends StatefulWidget {
  const AdminQuotesScreen({super.key});

  @override
  State<AdminQuotesScreen> createState() => _AdminQuotesScreenState();
}

class _AdminQuotesScreenState extends State<AdminQuotesScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchAdminQuotes();
    });
  }

  // Removed _pickAndUploadCustomImage as it is now handled by IconManagerDialog

  void _openIconManager(
      {bool isSelectionMode = false, Function(String)? onSelected}) {
    showDialog(
      context: context,
      builder: (context) => IconManagerDialog(
        isSelectionMode: isSelectionMode,
        onIconSelected: onSelected,
      ),
    );
  }

  // Removed _randomizeIcon as we now use random_gallery mode

  void _showAddQuoteDialog() {
    final textEnController = TextEditingController();
    final textHuController = TextEditingController();
    final authorController = TextEditingController();
    final titleEnController = TextEditingController(text: 'Study Break');
    final titleHuController = TextEditingController(text: 'Tanulás');
    String currentLang = 'en';
    String selectedIcon = 'menu_book_rounded';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        bool isTranslating = false;

        Future<void> translateField() async {
          // Logic: Translate FROM the other language TO the current language
          final sourceController =
              currentLang == 'en' ? textHuController : textEnController;
          final targetController =
              currentLang == 'en' ? textEnController : textHuController;
          final sourceLang = currentLang == 'en' ? 'hu' : 'en';
          final targetLang = currentLang;

          if (sourceController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Please enter ${sourceLang.toUpperCase()} text first')),
            );
            return;
          }

          setDialogState(() => isTranslating = true);

          final translated =
              await Provider.of<StatsProvider>(context, listen: false)
                  .translateText(sourceController.text, sourceLang, targetLang);

          setDialogState(() {
            isTranslating = false;
            if (translated != null && translated.isNotEmpty) {
              targetController.text = translated;
            }
          });
        }

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(AppLocalizations.of(context)!.adminAddQuote)),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("EN",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: currentLang == 'en',
                    onSelected: (val) =>
                        setDialogState(() => currentLang = 'en'),
                    selectedColor: CozyTheme.of(context).primary,
                    backgroundColor: CozyTheme.of(context).surface,
                    labelStyle: TextStyle(
                      color: currentLang == 'en'
                          ? CozyTheme.of(context).textInverse
                          : CozyTheme.of(context).textSecondary,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("HU",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: currentLang == 'hu',
                    onSelected: (val) =>
                        setDialogState(() => currentLang = 'hu'),
                    selectedColor: CozyTheme.of(context).primary,
                    backgroundColor: CozyTheme.of(context).surface,
                    labelStyle: TextStyle(
                      color: currentLang == 'hu'
                          ? CozyTheme.of(context).textInverse
                          : CozyTheme.of(context).textSecondary,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    text: currentLang == 'en'
                        ? textEnController.text
                        : textHuController.text,
                    author: authorController.text,
                    title: currentLang == 'en'
                        ? titleEnController.text
                        : titleHuController.text,
                    iconName: selectedIcon,
                  ),
                  const SizedBox(height: 24),

                  // ... inside _showAddQuoteDialog builder ...
                  // Icon Selection Row
                  Row(
                    children: [
                      // Small Preview Circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: CozyTheme.of(context).paperWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: CozyTheme.of(context)
                                    .textSecondary
                                    .withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: CozyTheme.of(context)
                                    .textPrimary
                                    .withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]),
                        child: (selectedIcon == 'random_gallery')
                            ? Icon(Icons.shuffle_rounded,
                                color: CozyTheme.of(context).accent, size: 24)
                            : (selectedIcon.startsWith('/') ||
                                    selectedIcon.startsWith('http'))
                                ? ClipOval(
                                    child: Image.network(
                                      '${ApiService.baseUrl}$selectedIcon',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.broken_image,
                                          size: 24,
                                          color: Colors.grey),
                                    ),
                                  )
                                : Icon(
                                    IconPickerDialog.getIconData(selectedIcon),
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
                                      color:
                                          CozyTheme.of(context).textInverse)),
                              backgroundColor: CozyTheme.of(context).primary,
                              onPressed: () {
                                _openIconManager(
                                  isSelectionMode: true,
                                  onSelected: (newIcon) {
                                    setDialogState(
                                        () => selectedIcon = newIcon);
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
                                      color:
                                          CozyTheme.of(context).textInverse)),
                              backgroundColor: CozyTheme.of(context).accent,
                              onPressed: () => setDialogState(
                                  () => selectedIcon = 'random_gallery'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DualLanguageField(
                    controllerEn: titleEnController,
                    controllerHu: titleHuController,
                    label: AppLocalizations.of(context)!.adminQuoteTitleLabel,
                    currentLanguage: currentLang,
                    isMultiLine: false,
                    onTranslate: null, // Title usually short
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 24),
                  DualLanguageField(
                    controllerEn: textEnController,
                    controllerHu: textHuController,
                    label: AppLocalizations.of(context)!.adminQuoteTextLabel,
                    currentLanguage: currentLang,
                    isMultiLine: true,
                    onTranslate: translateField,
                    isTranslating: isTranslating,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    decoration:
                        CozyTheme.inputDecoration(context, AppLocalizations.of(context)!.adminAuthorOptional),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (textEnController.text.isNotEmpty) {
                  final isCustom = selectedIcon.startsWith('/') ||
                      selectedIcon.startsWith('http');
                  final success =
                      await Provider.of<StatsProvider>(context, listen: false)
                          .createQuote(
                    textEnController.text,
                    textHuController.text,
                    authorController.text,
                    titleEn: titleEnController.text,
                    titleHu: titleHuController.text,
                    iconName: (selectedIcon == 'random_gallery')
                        ? 'random'
                        : (isCustom ? 'custom' : selectedIcon),
                    customIconUrl: (selectedIcon == 'random_gallery')
                        ? 'random_gallery'
                        : (isCustom ? selectedIcon : null),
                  );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(AppLocalizations.of(context)!.adminAddQuote,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showEditQuoteDialog(Quote quote) {
    final textEnController = TextEditingController(text: quote.textEn);
    final textHuController = TextEditingController(text: quote.textHu);
    final authorController = TextEditingController(text: quote.author);
    final titleEnController = TextEditingController(text: quote.titleEn);
    final titleHuController = TextEditingController(text: quote.titleHu);
    String currentLang = 'en';
    String selectedIcon =
        (quote.customIconUrl != null && quote.customIconUrl!.isNotEmpty)
            ? quote.customIconUrl!
            : quote.iconName;
    bool isTranslating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> translateField() async {
            // Logic: Translate FROM the other language TO the current language
            final sourceController =
                currentLang == 'en' ? textHuController : textEnController;
            final targetController =
                currentLang == 'en' ? textEnController : textHuController;
            final sourceLang = currentLang == 'en' ? 'hu' : 'en';
            final targetLang = currentLang;

            if (sourceController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Please enter ${sourceLang.toUpperCase()} text first')),
              );
              return;
            }

            setDialogState(() => isTranslating = true);

            final translated = await Provider.of<StatsProvider>(context,
                    listen: false)
                .translateText(sourceController.text, sourceLang, targetLang);

            setDialogState(() {
              isTranslating = false;
              if (translated != null && translated.isNotEmpty) {
                targetController.text = translated;
              }
            });
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(AppLocalizations.of(context)!.adminEditQuote,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("EN",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'en',
                      onSelected: (val) =>
                          setDialogState(() => currentLang = 'en'),
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).surface,
                      labelStyle: TextStyle(
                        color: currentLang == 'en'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).textSecondary,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'hu',
                      onSelected: (val) =>
                          setDialogState(() => currentLang = 'hu'),
                      selectedColor: CozyTheme.of(context).primary,
                      backgroundColor: CozyTheme.of(context).surface,
                      labelStyle: TextStyle(
                        color: currentLang == 'hu'
                            ? CozyTheme.of(context).textInverse
                            : CozyTheme.of(context).textSecondary,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                      text: currentLang == 'en'
                          ? textEnController.text
                          : textHuController.text,
                      author: authorController.text,
                      title: currentLang == 'en'
                          ? titleEnController.text
                          : titleHuController.text,
                      iconName: selectedIcon,
                    ),
                    const SizedBox(height: 24),
                    // Icon Selection Row (Edit Mode)
                    Row(
                      children: [
                        // Small Preview Circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: CozyTheme.of(context).paperWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: CozyTheme.of(context)
                                      .textSecondary
                                      .withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: CozyTheme.of(context)
                                      .textPrimary
                                      .withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]),
                          child: (selectedIcon == 'random_gallery')
                              ? Icon(Icons.shuffle_rounded,
                                  color: CozyTheme.of(context).accent, size: 24)
                              : (selectedIcon.startsWith('/') ||
                                      selectedIcon.startsWith('http'))
                                  ? ClipOval(
                                      child: Image.network(
                                        '${ApiService.baseUrl}$selectedIcon',
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(
                                            Icons.broken_image,
                                            size: 24,
                                            color: Colors.grey),
                                      ),
                                    )
                                  : Icon(
                                      IconPickerDialog.getIconData(
                                          selectedIcon),
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
                                        color:
                                            CozyTheme.of(context).textInverse)),
                                backgroundColor: CozyTheme.of(context).primary,
                                onPressed: () {
                                  _openIconManager(
                                    isSelectionMode: true,
                                    onSelected: (newIcon) {
                                      setDialogState(
                                          () => selectedIcon = newIcon);
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
                                        color:
                                            CozyTheme.of(context).textInverse)),
                                backgroundColor: CozyTheme.of(context).accent,
                                onPressed: () => setDialogState(
                                    () => selectedIcon = 'random_gallery'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DualLanguageField(
                      controllerEn: titleEnController,
                      controllerHu: titleHuController,
                      label: AppLocalizations.of(context)!.adminQuoteTitleLabel,
                      currentLanguage: currentLang,
                      isMultiLine: false,
                      onTranslate: translateField,
                      isTranslating: isTranslating,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                      onChanged: (val) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 24),
                    DualLanguageField(
                      controllerEn: textEnController,
                      controllerHu: textHuController,
                      label: AppLocalizations.of(context)!.adminQuoteTextLabel,
                      currentLanguage: currentLang,
                      isMultiLine: true,
                      onTranslate: translateField,
                      isTranslating: isTranslating,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                      onChanged: (val) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: authorController,
                      decoration: CozyTheme.inputDecoration(
                          context, AppLocalizations.of(context)!.adminAuthorOptional),
                      onChanged: (val) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton.icon(
                onPressed: isTranslating
                    ? null
                    : () async {
                        if (textEnController.text.isNotEmpty) {
                          final isCustom = selectedIcon.startsWith('/') ||
                              selectedIcon.startsWith('http');
                          final success = await Provider.of<StatsProvider>(
                                  context,
                                  listen: false)
                              .updateQuote(
                            quote.id,
                            textEnController.text,
                            textHuController.text,
                            authorController.text,
                            titleEn: titleEnController.text,
                            titleHu: titleHuController.text,
                            iconName: (selectedIcon == 'random_gallery')
                                ? 'random'
                                : (isCustom ? 'custom' : selectedIcon),
                            customIconUrl: (selectedIcon == 'random_gallery')
                                ? 'random_gallery'
                                : (isCustom ? selectedIcon : null),
                          );
                          if (success && context.mounted) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(AppLocalizations.of(context)!.adminQuoteUpdated)),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Quote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.adminDeleteQuote),
        content: Text(AppLocalizations.of(context)!.adminDeleteQuote), // Using same for now
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<StatsProvider>(context, listen: false)
                      .deleteQuote(quote.id);
              if (success && context.mounted) {
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: Padding(
        padding: const EdgeInsets.all(32), // Standardized 32px padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<StatsProvider>(
              builder: (context, stats, _) => _buildHeader(stats),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<StatsProvider>(
                builder: (context, stats, _) {
                  if (stats.isLoading && stats.adminQuotes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (stats.adminQuotes.isEmpty) {
                    return Center(
                      child: Text(
                        "No quotes found. Add some to start the rotation!",
                        style: TextStyle(
                            color: CozyTheme.of(context)
                                .textSecondary
                                .withValues(alpha: 0.5)),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: stats.adminQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = stats.adminQuotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // More rounded
                          side: BorderSide(
                              color: CozyTheme.of(context)
                                  .textSecondary
                                  .withValues(alpha: 0.1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EN: "${quote.textEn}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: CozyTheme.of(context).textPrimary,
                                ),
                              ),
                              if (quote.textHu.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'HU: "${quote.textHu}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: CozyTheme.of(context).textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              "- ${quote.author}",
                              style: TextStyle(
                                  color: CozyTheme.of(context).textSecondary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: CozyTheme.of(context).textSecondary,
                                    size: 20),
                                onPressed: () => _showEditQuoteDialog(quote),
                                tooltip: "Edit quote",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: CozyTheme.of(context).error,
                                    size: 20),
                                onPressed: () => _confirmDelete(quote),
                                tooltip: "Delete quote",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StatsProvider stats) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.adminQuotes,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CozyTheme.of(context).textPrimary,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminQuotesSubtitle,
              style: TextStyle(
                fontSize: 16,
                color: CozyTheme.of(context).textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildStatusChip("${stats.adminQuotes.length} ${l10n.adminQuotes}"),
            OutlinedButton.icon(
              onPressed: () => _openIconManager(isSelectionMode: false),
              icon: const Icon(Icons.collections, size: 18),
              label: Text(l10n.adminManageIcons),
              style: OutlinedButton.styleFrom(
                foregroundColor: CozyTheme.of(context).textPrimary,
                side: BorderSide(
                    color: CozyTheme.of(context)
                        .textPrimary
                        .withValues(alpha: 0.2)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddQuoteDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.adminAddQuote),
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.of(context).primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CozyTheme.of(context).shadowSmall,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: CozyTheme.of(context).textSecondary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand',
        ),
      ),
    );
  }
}
