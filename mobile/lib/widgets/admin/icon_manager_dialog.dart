import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/stats_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import 'icon_picker_dialog.dart'; // To access standard icons

class IconManagerDialog extends StatefulWidget {
  final bool isSelectionMode;
  final Function(String)? onIconSelected;

  const IconManagerDialog({
    super.key,
    this.isSelectionMode = false,
    this.onIconSelected,
  });

  @override
  State<IconManagerDialog> createState() => _IconManagerDialogState();
}

class _IconManagerDialogState extends State<IconManagerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // Upload State
  XFile? _selectedXFile; 
  String? _editingIconUrl; // If editing an existing icon
  double _previewScale = 1.0;
  bool _showBackground = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Refresh uploaded icons list when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchUploadedIcons();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedXFile = image;
        _editingIconUrl = null; // Clear editing mode if new pick
        _previewScale = 1.0; 
        _showBackground = true;
      });
      // automatically switch to Upload/Preview tab
    }
  }

  void _editExistingIcon(String iconUrl) {
    setState(() {
      _editingIconUrl = iconUrl;
      _selectedXFile = null; 
      _previewScale = 1.0; 
      _showBackground = true;
    });
    _tabController.animateTo(1); // Go to Editor
  }

  Future<void> _uploadImage() async {
    // We are either uploading a NEW file, or "Saving" an existing icon with new scale params.
    
    if (_editingIconUrl != null) {
      // Just return the existing URL with new Scale
      if (widget.isSelectionMode && widget.onIconSelected != null) {
        widget.onIconSelected!('$_editingIconUrl?scale=${_previewScale.toStringAsFixed(1)}&bg=$_showBackground');
        Navigator.pop(context);
        return;
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Preview settings saved. Select this icon to use it.')),
         );
         _tabController.animateTo(0);
         return;
      }
    }

    if (_selectedXFile == null) return;

    setState(() => _isUploading = true);

    try {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      
      // Pass folder=icons to backend via StatsProvider wrapper
      final url = await stats.uploadImage(_selectedXFile!, folder: 'icons');

      if (url != null) {
        await stats.fetchUploadedIcons(); // Refresh list

        if (!mounted) return; // Check mounted after await

        final finalUrlWithParams = '$url?scale=${_previewScale.toStringAsFixed(1)}&bg=$_showBackground';
        
        if (widget.isSelectionMode && widget.onIconSelected != null) {
          widget.onIconSelected!(finalUrlWithParams);
          if (mounted) Navigator.pop(context);
        } else {
          setState(() {
            _selectedXFile = null;
            _isUploading = false;
          });
          _tabController.animateTo(0); 
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Icon uploaded successfully')),
            );
          }
        }
      } else {
        throw Exception("Upload returned null");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteIcon(String iconUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Icon?"),
        content: const Text("This action cannot be undone. Quotes using this icon will break."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final success = await Provider.of<StatsProvider>(context, listen: false).deleteUploadedIcon(iconUrl);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Icon deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: widget.isSelectionMode 
          ? const EdgeInsets.only(top: 300, left: 20, right: 20, bottom: 20) // Shift down to see preview
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: SizedBox(
        width: widget.isSelectionMode ? 600 : 800, 
        height: widget.isSelectionMode ? 350 : 600,
        child: Column(
          children: [
            // Header with Tabs
            Container(
              decoration: BoxDecoration(
                color: CozyTheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isSelectionMode ? "Select Icon" : "Icon Manager",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isSelectionMode)
                    TabBar(
                      controller: _tabController,
                      labelColor: CozyTheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: CozyTheme.primary,
                      tabs: const [
                        Tab(text: "Gallery / Library"),
                        Tab(text: "Upload New"),
                      ],
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: widget.isSelectionMode 
                ? _buildGalleryTab()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGalleryTab(),
                      _buildUploadTab(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final uploaded = stats.uploadedIcons;
        final standardEntries = IconPickerDialog.availableIcons.entries.toList();
        
        // Total items = standard icons + custom icons
        final totalCount = standardEntries.length + uploaded.length;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 80, 
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: totalCount,
          itemBuilder: (ctx, index) {
            if (index < standardEntries.length) {
              // Standard Icon
              final entry = standardEntries[index];
              return InkWell(
                onTap: () {
                  if (widget.onIconSelected != null) {
                    widget.onIconSelected!(entry.key);
                    // Do NOT pop to allow "try-on"
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
                    ],
                  ),
                  child: Center(
                    child: Icon(entry.value, color: CozyTheme.primary, size: 28),
                  ),
                ),
              );
            } else {
              // Custom Uploaded Icon
              final customIndex = index - standardEntries.length;
              final url = uploaded[customIndex];
              final fullUrl = '${ApiService.baseUrl}$url';
              
              return Stack(
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.isSelectionMode && widget.onIconSelected != null) {
                        widget.onIconSelected!('$url?scale=1.0&bg=true');
                        // Do NOT pop to allow "try-on"
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isSelectionMode) ...[
                    // Delete Button 
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _deleteIcon(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.delete, size: 16, color: Colors.red),
                        ),
                      ),
                    ),
                    // Edit Button (Pencil)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _editExistingIcon(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: CozyTheme.accent),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildUploadTab() {
    // 🎨 Mimic QuotePreviewCard Styling
    const Color primaryColor = Color(0xFF8CAA8C); // Sage Green
    const Color textPrimary = Color(0xFF5D4037);
    const Color textSecondary = Color(0xFF8D6E63);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (_selectedXFile == null && _editingIconUrl == null)
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.none),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_rounded, size: 64, color: CozyTheme.primary),
                        const SizedBox(height: 16),
                        const Text("Click to Pick Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("PNG, JPG supported", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // 🖼️ PREVIEW SECTION (QuotePreviewCard Style)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 500, // Fixed width card
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF5E6), // Beige Background
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEEDCC5)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🟢 ICON PREVIEW
                          _showBackground 
                          ? Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: primaryColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: _buildPreviewImage(true),
                            )
                          : Container(
                              constraints: const BoxConstraints(
                                minWidth: 140,
                                minHeight: 140,
                                maxWidth: 200,
                                maxHeight: 200,
                              ),
                              child: _buildPreviewImage(false),
                            ),
                          const SizedBox(height: 16),
                          
                          // TITLE
                          Text(
                            "Study Break",
                            style: GoogleFonts.quicksand(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // SUBTITLE
                          Text(
                            "Quote text will appear here...",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textSecondary,
                              height: 1.3,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // 🎚️ CONTROLS
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          const Text("Zoom / Scale", style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.photo_size_select_small, size: 20, color: Colors.grey),
                              Expanded(
                                child: Slider(
                                  value: _previewScale,
                                  min: 0.5,
                                  max: 2.5, 
                                  divisions: 20,
                                  label: "${(_previewScale * 100).round()}%",
                                  onChanged: (val) => setState(() => _previewScale = val),
                                  activeColor: CozyTheme.primary,
                                ),
                              ),
                              const Icon(Icons.photo_size_select_large, size: 20, color: Colors.grey),
                            ],
                          ),
                          Text("${(_previewScale * 100).round()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                          
                          const SizedBox(height: 16),
                          // Toggle Background
                          SwitchListTile(
                            title: const Text("Show Circle Border", style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _showBackground, 
                            onChanged: (val) => setState(() => _showBackground = val),
                            activeThumbColor: CozyTheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),

                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Pick Different Image"),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Save Action
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CozyTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isUploading ? "Uploading..." : (_editingIconUrl != null ? "Save Changes" : "Save to Library"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewImage(bool useClip) {
    const double baseSize = 110.0; // Increased from 70 to match QuotePreviewCard

    final imageWidget = Transform.scale(
      scale: _previewScale,
      child: _editingIconUrl != null 
          ? Image.network(
              '${ApiService.baseUrl}$_editingIconUrl',
              width: baseSize * _previewScale,
              height: baseSize * _previewScale,
              fit: BoxFit.contain,
              errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
            )
          : (kIsWeb
              ? Image.network(
                  _selectedXFile!.path,
                  width: baseSize * _previewScale,
                  height: baseSize * _previewScale,
                  fit: BoxFit.contain,
                  errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                )
              : (Platform.isMacOS || Platform.isLinux || Platform.isWindows || Platform.isAndroid || Platform.isIOS ? 
                Image.file(
                  File(_selectedXFile!.path),
                  width: baseSize * _previewScale,
                  height: baseSize * _previewScale,
                  fit: BoxFit.contain,
                  errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                ) : const Icon(Icons.error))
            ),
    );

    return useClip ? ClipOval(child: imageWidget) : imageWidget;
  }
}
