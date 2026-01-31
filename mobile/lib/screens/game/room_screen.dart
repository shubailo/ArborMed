import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../services/auth_provider.dart';
import '../../services/stats_provider.dart'; // NEW IMPORT
import '../../models/user.dart'; // MISSING IMPORT
import '../../services/iso_service.dart';
import '../../widgets/shop/contextual_shop_sheet.dart';
import '../../widgets/avatar/bean_widget.dart';

import '../../widgets/quiz/quiz_portal.dart'; // Import the new portal
import '../../widgets/quiz/quiz_menu.dart'; // Import the menu

import '../../screens/game/quiz_loading_screen.dart';
import '../../screens/game/quiz_session_screen.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/hub/cozy_actions_overlay.dart';
import '../../widgets/hub/settings_sheet.dart';
import '../../widgets/profile/profile_portal.dart'; // NEW IMPORT
import '../../widgets/social/clinic_directory_sheet.dart';
import '../../services/social_provider.dart';
import '../../widgets/cozy/cozy_room_renderer.dart';
// import 'duel_lobby_screen.dart'; // NEW IMPORT

class RoomWidget extends StatefulWidget {
  const RoomWidget({super.key});

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial inventory state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ShopProvider>(context, listen: false);
      provider.fetchInventory();
      provider.startBuddyWander(); // Bring Hemmy to life!
      _centerRoom(); // Center immediately on load
    });
  }

  void _centerRoom() {
    final Size screenSize = MediaQuery.of(context).size;
    const double initialScale = 0.5; // Start mid-way
    
    // To center the scaled content:
    // We want the point (2500, 2500) of the child to be at (screenW/2, screenH/2).
    // The child is scaled by initialScale.
    
    final double startX = (screenSize.width / 2) - (2500 * initialScale);
    final double startY = (screenSize.height / 2) - (2500 * initialScale);
    
    _transformationController.value = Matrix4.identity()
      ..translate(startX, startY)
      ..scale(initialScale);
  }


  void _openQuizPortal() {
    // ... showGeneralDialog implementation ...
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QuizPortal',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return QuizFloatingWindow(
          onClose: () => Navigator.pop(context),
          child: QuizMenuWidget(
            onClose: () => Navigator.pop(context),
            onSystemSelected: (name, slug) {
              Navigator.pop(context); // Close the portal
              _startQuizSequence(name, slug); // Start transition
            },
          ),
        );
      },
    );
  }

  void _startQuizSequence(String name, String slug) {
    // 1. Push Loading Screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (routeContext, animation, secondaryAnimation) => QuizLoadingScreen(
          systemName: name,
          onAnimationComplete: () {
            // 2. Replace with Quiz Session (Using routeContext to replace loading screen)
            Navigator.of(routeContext).pushReplacement(
              MaterialPageRoute(builder: (_) => QuizSessionScreen(systemName: name, systemSlug: slug)),
            ).then((_) {
              if (!mounted) return;
              
              // 3. Handle Quiz End (Back in Room)
              // Re-center on return-to-base
              _centerRoom();
              
              // Refresh User State & Stats with local mounted check
              if (mounted) {
                Provider.of<AuthProvider>(context, listen: false).refreshUser();
                Provider.of<StatsProvider>(context, listen: false).fetchSummary();
              }
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showProfile() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProfilePortal',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return ProfilePortal(
          onSectionSelected: (name, slug) {
            Navigator.pop(context); // Close the portal
            _startQuizSequence(name, slug);
          },
        );
      },
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (_) => const SettingsSheet(),
    );
  }

  void _showLeaveNoteDialog(User colleague) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFDF5),
        title: Text("Consultation for Dr. ${colleague.username}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Leave a helpful observation..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<SocialProvider>(context, listen: false).leaveNote(colleague.id, noteController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note left in the records!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8CAA8C)),
            child: const Text("DISPATCH", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final social = Provider.of<SocialProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    final isDecorating = provider.isDecorating;
    final isVisiting = social.isVisiting;

    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD4E8E8), Color(0xFFE8F4F4)],
          ),
        ),
        child: Stack(
          children: [
            // 0. Fluid Background (Floating Medical Icons)
            const Positioned.fill(
              child: FloatingMedicalIcons(
                color: Color(0xFF8CAA8C), // Cozy Green/Primary
              ),
            ),

            // 1. New Cozy Renderer (Floating & Zoomable)
            // 1. New Cozy Renderer (Floating & Zoomable)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                panAxis: PanAxis.free, // Explicitly allow free panning
                boundaryMargin: const EdgeInsets.all(5000), // Huge scroll area 
                minScale: 0.1, // Zoom way out
                maxScale: 1.0, // Limit zoom in (prevent pixelation)
                constrained: false, 
                child: Container(
                  width: 5000,
                  height: 5000,
                  color: Colors.transparent, // Ensure empty space captures drags
                  alignment: Alignment.center,
                  child: Consumer<ShopProvider>(
                    builder: (context, provider, _) { 
                       return Stack(
                         alignment: Alignment.center,
                         children: [
                           CozyRoomRenderer(
                             room: provider.currentRoom,
                             equippedItems: provider.equippedItemsAsShopItems,
                             borderRadius: BorderRadius.circular(20),
                             ghostItems: provider.getGhostItems(), 
                             previewItem: provider.previewItem,
                             onItemTap: provider.isDecorating ? (item) {
                               print("👆 ROOM SCREEN TAPPED: ${item.name}");
                               // Get grid coords from item
                               int tx = 0, ty = 0;
                               final coords = provider.getSlotCoords(item.slotType);
                               if (coords != null) {
                                  tx = coords['x']!;
                                  ty = coords['y']!;
                               }
                                  
                               showDialog(
                                  context: context,
                                  builder: (ctx) => ContextualShopSheet(
                                    slotType: item.slotType,
                                    targetX: tx,
                                    targetY: ty,
                                  ),
                               );
                             } : null,
                           ),
                           // Overlay Removed - Interaction is now inside Renderer!
                         ],
                       );
                    },
                  ),
                ),
              ),
            ),
            
            // --- MAIN HUD OVERLAY ---
            // Only show when NOT decorating and NOT in full preview
            if (!isDecorating && !provider.isFullPreviewMode)
               CozyActionsOverlay(
                 coins: user?.coins ?? 0,
                 streak: user?.streakCount ?? 0,
                 isVisiting: isVisiting,
                 onProfileTap: _showProfile,
                 onNetworkTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ClinicDirectorySheet(),
                    );
                 },
                 onSettingsTap: _showSettings,
                  onEquipTap: () {
                   if (isVisiting) {
                     social.stopVisiting(context);
                   } else {
                     provider.toggleDecorateMode();
                   }
                  },
                  onStartTap: () {
                    if (isVisiting) {
                      _showLeaveNoteDialog(social.visitedUser!);
                    } else {
                      _openQuizPortal();
                    }
                  },
                  onLikeTap: isVisiting ? () => social.likeRoom(social.visitedUser!.id) : null,
                ),

            // Top-Left Visiting Badge
            if (isVisiting)
              Positioned(
                top: 100,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8CAA8C).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Office of: ${social.visitedUser?.displayName ?? social.visitedUser?.username ?? "Doctor"}",
                            style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // "DONE DECORATING" Button Overlay
            if (isDecorating)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: DoneEquippingButton(
                    onTap: () {
                      provider.toggleDecorateMode();
                      if (provider.isFullPreviewMode) provider.toggleFullPreview(false);
                    },
                  ),
                ),
              ),

            // "CLOSE PREVIEW" Button (Legacy - will be mostly hidden by DoneDecoratingButton)
            if (provider.isFullPreviewMode && !isDecorating)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: GestureDetector(
                    onTap: () {
                      provider.toggleFullPreview(false);
                      showDialog(
                        context: context,
                        builder: (_) => ContextualShopSheet(
                          slotType: provider.lastSlotType ?? 'floor',
                          targetX: provider.lastTargetX ?? 0,
                          targetY: provider.lastTargetY ?? 0,
                        ),
                      );
                    },
                    child: Container(
                      width: 250,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7E7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8B7355), width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: const Center(
                        child: Text(
                          'CLOSE PREVIEW', 
                          style: TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class IsometricRoom extends StatelessWidget {
  final List<UserItem> placedItems;
  final Map<String, UserItem?> avatarConfig;
  final ShopItem? previewItem;
  final int previewX;
  final int previewY;
  final bool isDecorating;
  
  // Buddy State
  final int buddyX;
  final int buddyY;
  final bool isBuddyWalking;
  final bool isBuddyHappy;

  static const double roomWidth = 500.0;
  static const double roomHeight = 400.0;

  const IsometricRoom({super.key, 
    required this.placedItems,
    required this.avatarConfig,
    this.previewItem,
    required this.previewX,
    required this.previewY,
    required this.isDecorating,
    required this.buddyX,
    required this.buddyY,
    required this.isBuddyWalking,
    required this.isBuddyHappy,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final social = Provider.of<SocialProvider>(context);
    const double centerX = 1000.0;
    const double centerY = 1000.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Hexagonal Room Base
        Positioned(
          left: centerX - roomWidth / 2,
          top: centerY - roomHeight / 2,
          child: CustomPaint(
            size: const Size(roomWidth, roomHeight),
            painter: SimpleHexRoomPainter(),
          ),
        ),
        
        // 3. Placed Items (Sorted by Depth)
        ...placedItems.map((item) => 
          _buildItem(item.name, item.x ?? 0, item.y ?? 0, centerX, centerY, 
            isGhost: false, 
            assetPath: item.assetPath,
            slotType: item.slotType)),
        
        // 4. Ghost Blueprints (Only visible in Decorate Mode + if category not placed + NOT VISITING)
        if (isDecorating && !social.isVisiting) ..._buildGhostBlueprints(context, centerX, centerY, provider),

        // 5. Avatar (Bean) - Centered for now
        _buildAvatar(centerX, centerY, context),
        
        // 6. Preview Item (Solid Mode from Shop as requested)
        if (previewItem != null)
          _buildItem(previewItem!.name, previewX, previewY, centerX, centerY, 
            isGhost: false, // User wants preview to be solid
            isPreview: true,
            assetPath: previewItem!.assetPath,
            slotType: previewItem!.slotType),
      ],
    );
  }

  List<Widget> _buildGhostBlueprints(BuildContext context, double cx, double cy, ShopProvider provider) {
    // These are the "Perfect" Clinical Slots we've been tuning
    final blueprints = [
      {'name': 'Modern Glass Desk', 'x': 0, 'y': 2, 'type': 'desk', 'path': 'assets/images/furniture/desk.webp'},
      {'name': 'Vital Monitor stand', 'x': 3, 'y': -1, 'type': 'monitor', 'path': 'assets/images/furniture/monitor.webp'},
      {'name': 'Wall-mounted AC Unit', 'x': 1, 'y': 2, 'type': 'wall_ac', 'path': 'assets/images/furniture/ac.webp'},
      {'name': 'Blue Gurney', 'x': 2, 'y': -1, 'type': 'exam_table', 'path': 'assets/images/furniture/gurney.webp'},
      {'name': 'Geometric Wall Art', 'x': 0, 'y': 2, 'type': 'wall_decor', 'path': 'assets/images/furniture/wall_decor.webp'},
    ];

    debugPrint("👻 Building Ghost Blueprints: ${blueprints.length} candidates");

    return blueprints.where((bp) {
      // Hide the blueprint if a real item of this type is already placed
      return !provider.isItemTypePlaced(bp['type'] as String);
    }).map((bp) {
      debugPrint("  -> Rendering Ghost: ${bp['name']} at (${bp['x']}, ${bp['y']})");
      return _buildItem(
        bp['name'] as String, 
        bp['x'] as int, bp['y'] as int, 
        cx, cy, 
        isGhost: false, // buildItem handles its own logic, we'll use isBlueprint flag soon if needed
        isBlueprint: true,
        assetPath: bp['path'] as String,
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => ContextualShopSheet(
              slotType: bp['type'] as String,
              targetX: bp['x'] as int,
              targetY: bp['y'] as int,
            ),
          );
        }
      );
    }).toList();
  }

  Widget _buildItem(String name, int gridX, int gridY, double cx, double cy, {
    required bool isGhost, 
    String? assetPath, 
    bool isBlueprint = false,
    bool isPreview = false,
    String? slotType,
    VoidCallback? onTap,
  }) {
    // Standard isometric mapping
    final screenCoords = IsoService.gridToScreen(gridX, gridY);
    
    double verticalOffset = -80; // Standard floor baseline
    double horizontalOffset = -120; // Centering larger widths
    
    // 🩺 ROBUST MAPPING: Use SlotType for all items in a category
    if (slotType == 'wall_ac' || name.contains('AC')) {
      verticalOffset = -164; 
      horizontalOffset = -125; 
    } else if (slotType == 'wall_calendar' || name.contains('Calendar')) {
      verticalOffset = -180; 
    } else if (slotType == 'monitor' || name.contains('Monitor')) {
      verticalOffset = -100; 
      horizontalOffset = -160; 
    } else if (slotType == 'exam_table' || name.contains('Gurney')) {
      verticalOffset = -44; // Precision grounded
      horizontalOffset = -95; 
    } else if (slotType == 'desk' || name.contains('Desk')) {
      verticalOffset = -64; 
      horizontalOffset = -125; 
    }
    
    return Positioned(
      left: cx + screenCoords[0] + horizontalOffset,
      top: cy + screenCoords[1] + verticalOffset,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isBlueprint ? 0.4 : (isPreview ? 0.8 : (isGhost ? 0.6 : 1.0)),
          child: ItemGraphic(name: name, isGhost: isGhost, imagePath: assetPath, slotType: slotType),
        ),
      ),
    );
  }

  Widget _buildAvatar(double cx, double cy, BuildContext context) {
    final screenCoords = IsoService.gridToScreen(buddyX, buddyY);

    return AnimatedPositioned(
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      left: cx + screenCoords[0] - 125, // Centered (half of 250)
      top: cy + screenCoords[1] - 150, // Lowered to feet land on floor (was -200)
      child: GestureDetector(
        onTap: () {
          Provider.of<ShopProvider>(context, listen: false).triggerBuddyHappy();
        },
        child: BeanWidget(
          config: avatarConfig,
          size: 250,
          isWalking: isBuddyWalking,
          isHappy: isBuddyHappy,
        ),
      ),
    );
  }

  List<Widget> _buildDecorationButtons(BuildContext context, double cx, double cy) {
    // REDUCED: Only the core Clinical Slots for the overhaul step-by-step
    final suggestedSpots = [
      {'x': 1, 'y': 3, 'type': 'desk'},
      {'x': 2, 'y': -2, 'type': 'exam_table'},
    ];

    return suggestedSpots.where((spot) {
      // Hiding the (+) button during specific slot preview
      final isPreviewingHere = previewItem != null && 
                               previewX == (spot['x'] as int) && 
                               previewY == (spot['y'] as int);
      return !isPreviewingHere;
    }).map((spot) {
      final screenCoords = IsoService.gridToScreen(spot['x'] as int, spot['y'] as int);

      return Positioned(
        left: cx + screenCoords[0] - 25,
        top: cy + screenCoords[1] - (spot['type'].toString().contains('wall') ? 100 : 25),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => ContextualShopSheet(
                slotType: spot['type'] as String,
                targetX: spot['x'] as int,
                targetY: spot['y'] as int,
              ),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7E7), // Cozy Cream
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B7355), width: 4), // Thick Pro Border
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 32,
              color: Color(0xFF8B7355),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class DoneEquippingButton extends StatelessWidget {
  final VoidCallback onTap;
  const DoneEquippingButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B7355), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: const Center(
          child: Text(
            'DONE EQUIPPING', 
            style: TextStyle(
              color: Color(0xFF5D4037), 
              fontWeight: FontWeight.w900, 
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleHexRoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    
    // Hexagon points
    final Offset top = Offset(cx, 0);
    final Offset topRight = Offset(w * 0.85, h * 0.25);
    final Offset bottomRight = Offset(w * 0.85, h * 0.75);
    final Offset bottom = Offset(cx, h);
    final Offset bottomLeft = Offset(w * 0.15, h * 0.75);
    final Offset topLeft = Offset(w * 0.15, h * 0.25);
    final Offset center = Offset(cx, cy);
    
    // Shadow
    final shadowPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..close();
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(shadowPath.shift(const Offset(0, 10)), shadowPaint);
    
    // WALLS & FLOOR
    // Right wall
    final rightWallPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    
    canvas.drawPath(rightWallPath, Paint()..color = const Color(0xFF7A95B8));
    
    // Floor
    final floorPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    
    canvas.drawPath(floorPath, Paint()..color = const Color(0xFF9B7653));
    
    // Left wall
    final leftWallPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..close();
    
    canvas.drawPath(leftWallPath, Paint()..color = const Color(0xFF5C7A99));
    
    // Border
    final borderPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..close();
    
    canvas.drawPath(borderPath, Paint()
      ..color = const Color(0xFF8B7355)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ItemGraphic extends StatelessWidget {
  final String name;
  final bool isGhost;
  final String? imagePath;
  final String? slotType;

  const ItemGraphic({
    Key? key, 
    required this.name, 
    this.isGhost = false,
    this.imagePath,
    this.slotType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🖼️ Priority 1: Direct Image Path from DB (Standard for Pro Furniture)
    if (imagePath != null && imagePath!.isNotEmpty) {
      double scale = 2.0; 
      
      // 🩺 Slot-Based Scaling
      if (slotType == 'exam_table' || name.contains('Gurney')) {
        scale = 2.1;
      } 
      if (slotType == 'desk' || name.contains('Desk')) {
        scale = 2.1;
      }   
      if (slotType == 'monitor' || name.contains('Monitor')) {
        scale = 2.0;
      } 
      if (slotType == 'wall_ac' || name.contains('AC')) {
        scale = 1.1;
      } 
      if (slotType == 'wall_calendar' || name.contains('Calendar')) {
        scale = 1.4;
      }

      return Opacity(
        opacity: isGhost ? 0.6 : 1.0,
        child: SizedBox(
          width: 80 * scale,
          height: 80 * scale,
          child: Image.asset(
            imagePath!, 
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Icon(Icons.medical_services_outlined, size: 60, color: Colors.brown[300]),
          ),
        ),
      );
    }

    // 🧱 Priority 2: Legacy Icons
    IconData iconData = Icons.chair_outlined;
    Color iconColor = const Color(0xFF6D4C41);
    
    if (name.contains('Table')) {
      iconData = Icons.airline_seat_flat_angled;
    } else if (name.contains('Book')) iconData = Icons.menu_book;
    else if (name.contains('Microscope')) iconData = Icons.biotech;
    else if (name.contains('Coat')) iconData = Icons.checkroom;
    else if (name.contains('Plant')) {
      iconData = Icons.eco;
      iconColor = Colors.green[800]!;
    }
    else if (name.contains('Espresso') || name.contains('Coffee')) {
      iconData = Icons.coffee_maker;
    }
    else if (name.contains('Rug')) {
      iconData = Icons.grid_view_sharp;
    }

    return Opacity(
      opacity: isGhost ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGhost ? Colors.grey.withOpacity(0.2) : const Color(0xFFEFEBE9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isGhost ? Colors.grey.withOpacity(0.4) : const Color(0xFF8D6E63),
            width: 3,
          ),
        ),
        child: Icon(
          iconData,
          size: 48,
          color: isGhost ? Colors.grey : iconColor,
        ),
      ),
    );
  }
}
