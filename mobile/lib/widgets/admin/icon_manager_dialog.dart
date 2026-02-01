import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
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
    Key? key,
    this.isSelectionMode = false,
    this.onIconSelected,
  }) : super(key: key);

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
      });
      // automatically switch to Upload/Preview tab
    }
  }

  void _editExistingIcon(String iconUrl) {
    setState(() {
      _editingIconUrl = iconUrl;
      _selectedXFile = null; 
      _previewScale = 1.0; // Reset scale 
    });
    _tabController.animateTo(1); // Go to Editor
  }

  Future<void> _uploadImage() async {
    // We are either uploading a NEW file, or "Saving" an existing icon with new scale params.
    
    if (_editingIconUrl != null) {
      // Just return the existing URL with new Scale
      if (widget.isSelectionMode && widget.onIconSelected != null) {
        widget.onIconSelected!('$_editingIconUrl?scale=${_previewScale.toStringAsFixed(1)}&bg=true');
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

        final finalUrlWithParams = '$url?scale=${_previewScale.toStringAsFixed(1)}&bg=true';
        
        if (widget.isSelectionMode && widget.onIconSelected != null) {
          widget.onIconSelected!(finalUrlWithParams);
          Navigator.pop(context);
        } else {
          setState(() {
            _selectedXFile = null;
            _isUploading = false;
          });
          _tabController.animateTo(0); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Icon uploaded successfully')),
          );
        }
      } else {
        throw Exception("Upload returned null");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      setState(() => _isUploading = false);
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
      child: SizedBox(
        width: 800, // Large specific width
        height: 600,
        child: Column(
          children: [
            // Header with Tabs
            Container(
              decoration: BoxDecoration(
                color: CozyTheme.primary.withOpacity(0.05),
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
              child: TabBarView(
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
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Icons Section (Only if in Selection Mode)
            if (widget.isSelectionMode)
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Standard Icons", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: IconPickerDialog.availableIcons.length,
                          itemBuilder: (ctx, index) {
                            final key = IconPickerDialog.availableIcons.keys.elementAt(index);
                            final iconData = IconPickerDialog.availableIcons.values.elementAt(index);
                            return InkWell(
                              onTap: () {
                                if (widget.onIconSelected != null) {
                                  widget.onIconSelected!(key);
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(iconData, color: CozyTheme.primary, size: 24),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Uploaded Icons Section
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("My Custom Icons", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  if (uploaded.isEmpty)
                    const Expanded(child: Center(child: Text("No custom icons yet.\nSwitch to 'Upload New' tab.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))),
                  
                  if (uploaded.isNotEmpty)
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120, // Wider for custom previews
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: uploaded.length,
                        itemBuilder: (ctx, index) {
                          final url = uploaded[index];
                          // Note: saved icons might already have params, but the list from server is usually raw filenames.
                          // We construct the full URL.
                          final fullUrl = '${ApiService.baseUrl}$url';
                          
                          return Stack(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (widget.isSelectionMode && widget.onIconSelected != null) {
                                    // Append default formatting
                                    widget.onIconSelected!('$url?scale=1.0&bg=true');
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      fullUrl,
                                      fit: BoxFit.cover, // Or contain to see whole image
                                      errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                ),
                              ),
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
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadTab() {
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
                        Icon(Icons.add_photo_alternate_rounded, size: 64, color: CozyTheme.primary),
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
            // Preview Stats
            Expanded(
              child: Row(
                children: [
                  // Left: Editor Controls
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Preview & Resize", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Adjust standard sizing for this icon.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),
                        const Text("Scale / Zoom", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.photo_size_select_small, size: 16),
                            Expanded(
                              child: Slider(
                                value: _previewScale,
                                min: 0.5,
                                max: 2.0,
                                divisions: 15,
                                label: "${(_previewScale * 100).round()}%",
                                onChanged: (val) => setState(() => _previewScale = val),
                                activeColor: CozyTheme.primary,
                              ),
                            ),
                            const Icon(Icons.photo_size_select_large, size: 16),
                          ],
                        ),
                        Center(child: Text("${(_previewScale * 100).round()}%")),
                        
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: _pickImage, // Re-pick
                          icon: const Icon(Icons.refresh),
                          label: const Text("Choose Different Image"),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right: Live Preview
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Quote Card Preview", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          // Mockup of the Title + Icon part
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1), // Background color from screenshot
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // The Icon Widget logic
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: _previewScale,
                                      child: _editingIconUrl != null 
                                          ? Image.network(
                                              '${ApiService.baseUrl}$_editingIconUrl',
                                              fit: BoxFit.cover,
                                              errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                                            )
                                          : (kIsWeb
                                              ? Image.network(
                                                  _selectedXFile!.path,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                                                )
                                              : (Platform.isMacOS || Platform.isLinux || Platform.isWindows || Platform.isAndroid || Platform.isIOS ? 
                                                Image.file(
                                                  File(_selectedXFile!.path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                                                ) : const Icon(Icons.error))
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Preview Title", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                                    Text("Preview Author", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Save Action
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CozyTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? "Uploading..." : (_editingIconUrl != null ? "Save Selection" : "Save to Library")),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
