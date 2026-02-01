import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/admin/dual_language_field.dart';
import '../../widgets/admin/quote_preview_card.dart';
import '../../widgets/admin/icon_picker_dialog.dart';
import '../../widgets/admin/icon_manager_dialog.dart';
import '../../services/api_service.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
class AdminQuotesScreen extends StatefulWidget {
  const AdminQuotesScreen({Key? key}) : super(key: key);

  @override
  State<AdminQuotesScreen> createState() => _AdminQuotesScreenState();
}

class _AdminQuotesScreenState extends State<AdminQuotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchAdminQuotes();
    });
  }

  // Removed _pickAndUploadCustomImage as it is now handled by IconManagerDialog

  void _openIconManager({bool isSelectionMode = false, Function(String)? onSelected}) {
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isTranslating = false;

          Future<void> translateField() async {
            // Logic: Translate FROM the other language TO the current language
            final sourceController = currentLang == 'en' ? textHuController : textEnController;
            final targetController = currentLang == 'en' ? textEnController : textHuController;
            final sourceLang = currentLang == 'en' ? 'hu' : 'en';
            final targetLang = currentLang;

            if (sourceController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter ${sourceLang.toUpperCase()} text first')),
              );
              return;
            }

            setDialogState(() => isTranslating = true);
            
            final translated = await Provider.of<StatsProvider>(context, listen: false)
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
                const Text("Add New Quote"),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("EN", style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'en',
                      onSelected: (val) => setDialogState(() => currentLang = 'en'),
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: currentLang == 'en' ? Colors.white : Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU", style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'hu',
                      onSelected: (val) => setDialogState(() => currentLang = 'hu'),
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: currentLang == 'hu' ? Colors.white : Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 500, // Explicitly wider as requested
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuotePreviewCard(
                      text: currentLang == 'en' ? textEnController.text : textHuController.text,
                      author: authorController.text,
                      title: currentLang == 'en' ? titleEnController.text : titleHuController.text,
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                               BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: (selectedIcon == 'random_gallery')
                            ? const Icon(Icons.shuffle_rounded, color: CozyTheme.accent, size: 24)
                            : (selectedIcon.startsWith('/') || selectedIcon.startsWith('http')) 
                                ? ClipOval(
                                    child: Image.network(
                                      '${ApiService.baseUrl}$selectedIcon',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  )
                                : Icon(
                                    IconPickerDialog.getIconData(selectedIcon), 
                                    color: CozyTheme.primary,
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
                                avatar: const Icon(Icons.grid_view, size: 16, color: Colors.white),
                                label: const Text("Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: CozyTheme.primary,
                                onPressed: () {
                                  _openIconManager(
                                    isSelectionMode: true,
                                    onSelected: (newIcon) {
                                      setDialogState(() => selectedIcon = newIcon);
                                    },
                                  );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.shuffle, size: 16, color: Colors.white),
                                label: const Text("Random", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: CozyTheme.accent,
                                onPressed: () => setDialogState(() => selectedIcon = 'random_gallery'),
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
                          label: "Title (e.g. Study Break)",
                          currentLanguage: currentLang,
                          isMultiLine: false,
                          onTranslate: null, // Title usually short
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                    const SizedBox(height: 24),
                    DualLanguageField(
                      controllerEn: textEnController,
                      controllerHu: textHuController,
                      label: "Quote Text",
                      currentLanguage: currentLang,
                      isMultiLine: true,
                      onTranslate: translateField,
                      isTranslating: isTranslating,
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: "Author (Optional)",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (textEnController.text.isNotEmpty) {
                    final isCustom = selectedIcon.startsWith('/') || selectedIcon.startsWith('http');
                    final success = await Provider.of<StatsProvider>(context, listen: false)
                        .createQuote(
                          textEnController.text,
                          textHuController.text,
                          authorController.text,
                          titleEn: titleEnController.text,
                          titleHu: titleHuController.text,
                          iconName: (selectedIcon == 'random_gallery') ? 'random' : (isCustom ? 'custom' : selectedIcon),
                          customIconUrl: (selectedIcon == 'random_gallery') ? 'random_gallery' : (isCustom ? selectedIcon : null),
                        );
                    if (success && mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Add Quote", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditQuoteDialog(Quote quote) {
    final textEnController = TextEditingController(text: quote.textEn);
    final textHuController = TextEditingController(text: quote.textHu);
    final authorController = TextEditingController(text: quote.author);
    final titleEnController = TextEditingController(text: quote.titleEn);
    final titleHuController = TextEditingController(text: quote.titleHu);
    String currentLang = 'en';
    String selectedIcon = (quote.customIconUrl != null && quote.customIconUrl!.isNotEmpty) 
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
            final sourceController = currentLang == 'en' ? textHuController : textEnController;
            final targetController = currentLang == 'en' ? textEnController : textHuController;
            final sourceLang = currentLang == 'en' ? 'hu' : 'en';
            final targetLang = currentLang;

            if (sourceController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter ${sourceLang.toUpperCase()} text first')),
              );
              return;
            }

            setDialogState(() => isTranslating = true);
            
            final translated = await Provider.of<StatsProvider>(context, listen: false)
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
                const Text("Edit Quote", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("EN", style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'en',
                      onSelected: (val) => setDialogState(() => currentLang = 'en'),
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: currentLang == 'en' ? Colors.white : Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("HU", style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: currentLang == 'hu',
                      onSelected: (val) => setDialogState(() => currentLang = 'hu'),
                      selectedColor: CozyTheme.primary,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: currentLang == 'hu' ? Colors.white : Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuotePreviewCard(
                      text: currentLang == 'en' ? textEnController.text : textHuController.text,
                      author: authorController.text,
                      title: currentLang == 'en' ? titleEnController.text : titleHuController.text,
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                               BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: (selectedIcon == 'random_gallery')
                            ? const Icon(Icons.shuffle_rounded, color: CozyTheme.accent, size: 24)
                            : (selectedIcon.startsWith('/') || selectedIcon.startsWith('http')) 
                                ? ClipOval(
                                    child: Image.network(
                                      '${ApiService.baseUrl}$selectedIcon',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  )
                                : Icon(
                                    IconPickerDialog.getIconData(selectedIcon), 
                                    color: CozyTheme.primary,
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
                                avatar: const Icon(Icons.grid_view, size: 16, color: Colors.white),
                                label: const Text("Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: CozyTheme.primary,
                                onPressed: () {
                                  _openIconManager(
                                    isSelectionMode: true,
                                    onSelected: (newIcon) {
                                      setDialogState(() => selectedIcon = newIcon);
                                    },
                                  );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.shuffle, size: 16, color: Colors.white),
                                label: const Text("Random", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: CozyTheme.accent,
                                onPressed: () => setDialogState(() => selectedIcon = 'random_gallery'),
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
                          label: "Title",
                          currentLanguage: currentLang,
                          isMultiLine: false,
                          onTranslate: translateField,
                          isTranslating: isTranslating,
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                    const SizedBox(height: 24),
                    DualLanguageField(
                      controllerEn: textEnController,
                      controllerHu: textHuController,
                      label: "Quote Text",
                      currentLanguage: currentLang,
                      isMultiLine: true,
                      onTranslate: translateField,
                      isTranslating: isTranslating,
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: authorController,
                      decoration: InputDecoration(
                        labelText: "Author (Optional)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                onPressed: isTranslating ? null : () async {
                  if (textEnController.text.isNotEmpty) {
                    final isCustom = selectedIcon.startsWith('/') || selectedIcon.startsWith('http');
                    final success = await Provider.of<StatsProvider>(context, listen: false)
                        .updateQuote(
                          quote.id,
                          textEnController.text,
                          textHuController.text,
                          authorController.text,
                          titleEn: titleEnController.text,
                          titleHu: titleHuController.text,
                          iconName: (selectedIcon == 'random_gallery') ? 'random' : (isCustom ? 'custom' : selectedIcon),
                          customIconUrl: (selectedIcon == 'random_gallery') ? 'random_gallery' : (isCustom ? selectedIcon : null),
                        );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quote updated successfully')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        title: const Text("Delete Quote?"),
        content: const Text("Are you sure you want to delete this quote?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StatsProvider>(context, listen: false)
                  .deleteQuote(quote.id);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Motivational Quotes",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
              ),
              Row(
                children: [
                   OutlinedButton.icon(
                    onPressed: () => _openIconManager(isSelectionMode: false),
                    icon: const Icon(Icons.collections),
                    label: const Text("Manage Icons"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5D4037),
                      side: const BorderSide(color: Color(0xFF5D4037)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddQuoteDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Quote"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CozyTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
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
                      style: TextStyle(color: Colors.grey[400]),
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
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EN: "${quote.textEn}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (quote.textHu.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'HU: "${quote.textHu}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "- ${quote.author}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF7FA08C), size: 20),
                              onPressed: () => _showEditQuoteDialog(quote),
                              tooltip: "Edit quote",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
    );
  }
}
