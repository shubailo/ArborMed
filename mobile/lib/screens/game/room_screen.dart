import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_provider.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../services/auth_provider.dart';
import '../../services/stats_provider.dart'; // NEW IMPORT
import '../../models/user.dart';
import '../../services/iso_service.dart';
import '../../widgets/shop/contextual_shop_sheet.dart';
import '../../widgets/avatar/bean_widget.dart';

import '../../widgets/quiz/quiz_portal.dart'; // Import the new portal
import '../../widgets/quiz/quiz_menu.dart'; // Import the menu
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';

import '../../screens/game/quiz_loading_screen.dart';
import '../../screens/game/quiz_session_screen.dart';
import '../../services/question_cache_service.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/hub/cozy_actions_overlay.dart';
import '../../widgets/hub/settings_sheet.dart';
import '../../widgets/profile/profile_portal.dart'; // NEW IMPORT
import '../../widgets/social/clinic_directory_sheet.dart';
import '../../services/social_provider.dart';
import '../../widgets/cozy/cozy_room_renderer.dart';
import '../../widgets/cozy/cozy_button.dart';
// import 'duel_lobby_screen.dart'; // NEW IMPORT

class RoomWidget extends StatefulWidget {
  const RoomWidget({super.key});

  @override
  createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _entryController;
  Animation<double>? _entryAnimation;

  @override
  void dispose() {
    _transformationController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // Snappier entry
    );

    // Parallelize all background fetches to ensure a buttery-smooth cinematic entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = Provider.of<ShopProvider>(context, listen: false);
      final stats = Provider.of<StatsProvider>(context, listen: false);
      final audio = Provider.of<AudioProvider>(context, listen: false);

      Future.wait([
        shop.fetchInventory(),
        stats.preFetchData(),
      ]).catchError((e) {
        debugPrint("Background fetch error: $e");
        return [];
      });

      shop.startBuddyWander();
      audio.fadeIn();

      _startCinematicEntry();
    });
  }

  void _startCinematicEntry() {
    final Size screenSize = MediaQuery.of(context).size;
    const double finalScale = 0.4; // Slightly smaller for "bigger space" feel
    const double startScale = 0.2;

    final double endX = (screenSize.width / 2) - (2500 * finalScale);
    final double endY = (screenSize.height / 2) - (2500 * finalScale);

    final double startX = (screenSize.width / 2) - (2500 * startScale);
    final double startY = (screenSize.height / 2) - (2500 * startScale);

    _entryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart)) // Snappier curve
      ..addListener(() {
        final double v = _entryAnimation!.value;
        final double currentScale = startScale + (finalScale - startScale) * v;
        final double currentX = startX + (endX - startX) * v;
        final double currentY = startY + (endY - startY) * v;

        _transformationController.value =
            Matrix4.translationValues(currentX, currentY, 0.0) *
                Matrix4.diagonal3Values(currentScale, currentScale, 1.0);
      });

    _entryController.forward();
  }

  void _centerRoom({bool animate = true, double? targetScale}) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scale = targetScale ?? 0.4; // Default to 0.4 if not provided

    final double targetX = (screenSize.width / 2) - (2500 * scale);
    final double targetY = (screenSize.height / 2) - (2500 * scale);

    final Matrix4 endValue = Matrix4.translationValues(targetX, targetY, 0.0) *
        Matrix4.diagonal3Values(scale, scale, 1.0);

    if (animate) {
      _animateToMatrix(endValue, durationMs: 1000); // Gentler snap
    } else {
      _transformationController.value = endValue;
    }
  }

  void _animateToMatrix(Matrix4 target, {int durationMs = 600}) {
    _entryAnimation?.removeListener(() {});

    final Matrix4 start = _transformationController.value;
    final AnimationController anim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    final Animation<double> curve = CurvedAnimation(
        parent: anim, curve: Curves.easeInOutCubic); // Smoother curve

    anim.addListener(() {
      _transformationController.value =
          _interpolateMatrix(start, target, curve.value);
    });

    anim.forward().then((_) => anim.dispose());
  }

  Matrix4 _interpolateMatrix(Matrix4 a, Matrix4 b, double t) {
    final Matrix4 res = Matrix4.zero();
    for (int i = 0; i < 16; i++) {
      res.storage[i] = a.storage[i] + (b.storage[i] - a.storage[i]) * t;
    }
    return res;
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
    final api = ApiService();
    final cache = Provider.of<QuestionCacheService>(context, listen: false);

    // 🚀 Smart Orchestration: Start everything in background immediately
    final Future<Map<String, dynamic>> dataFuture = Future(() async {
      // 1. Initialize Cache
      await cache.init(slug);

      // 2. Start Session
      final session = await api.post('/quiz/start', {});
      final String sessionId = session['id'].toString();

      // 3. Get First Question
      final firstQuestion = cache.next();

      return {
        'question': firstQuestion,
        'sessionId': sessionId,
      };
    });

    // 1. Push Loading Screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (routeContext, animation, secondaryAnimation) =>
            QuizLoadingScreen(
          systemName: name,
          dataFuture: dataFuture,
          onComplete: (data) {
            // 2. Replace with Quiz Session (Using pre-fetched data)
            Navigator.of(routeContext)
                .pushReplacement(
              MaterialPageRoute(
                  builder: (_) => QuizSessionScreen(
                        systemName: name,
                        systemSlug: slug,
                        initialData: data['question'],
                        sessionId: data['sessionId'],
                      )),
            )
                .then((_) {
              if (!mounted) return;

              // 3. Handle Quiz End (Back in Room)
              _centerRoom();

              if (mounted) {
                Provider.of<AuthProvider>(context, listen: false).refreshUser();
                Provider.of<StatsProvider>(context, listen: false)
                    .fetchSummary();
                Provider.of<StatsProvider>(context, listen: false)
                    .fetchSubjectDetail(slug);
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
        title: Text("Consultation for ${colleague.username}",
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: "Leave a helpful observation..."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<SocialProvider>(context, listen: false)
                    .leaveNote(colleague.id, noteController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Note left in the records!")));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CAA8C)),
            child:
                const Text("DISPATCH", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Returns a subtle ambient overlay color based on time of day
  Color _getAmbientOverlay() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 12) {
      // Morning: Warm golden tint
      return const Color(0xFFF5D78E).withValues(alpha: 0.08);
    } else if (hour >= 12 && hour < 18) {
      // Afternoon: Neutral (no tint)
      return Colors.transparent;
    } else if (hour >= 18 && hour < 21) {
      // Evening: Soft orange sunset
      return const Color(0xFFE8A87C).withValues(alpha: 0.10);
    } else {
      // Night: Subtle blue moonlight
      return const Color(0xFF7B9EC8).withValues(alpha: 0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final social = Provider.of<SocialProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    final isDecorating = provider.isDecorating;
    final isVisiting = social.isVisiting;

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CozyTheme.of(context).background,
              CozyTheme.of(context).surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 0. Fluid Background (Floating Medical Icons)
            Positioned.fill(
              child: FloatingMedicalIcons(
                color: CozyTheme.of(context).primary,
              ),
            ),

            // 0.5 Day/Night Ambient Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: _getAmbientOverlay(),
                ),
              ),
            ),

            // 1. New Cozy Renderer (Floating & Zoomable)
            // 1. New Cozy Renderer (Floating & Zoomable)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                panAxis: PanAxis.free, // Explicitly allow free panning
                boundaryMargin: const EdgeInsets.all(5000),
                minScale: 0.1,
                maxScale: 2.0, // Allow deeper zoom
                constrained: false,
                onInteractionEnd: (details) {
                  // 🩺 Refinement: Light Roebound Snapback
                  final matrix = _transformationController.value;
                  final x = matrix.getTranslation().x;
                  final y = matrix.getTranslation().y;
                  final scale = matrix.getMaxScaleOnAxis();

                  final Size screenSize = MediaQuery.of(context).size;

                  // Expected center translation for CURRENT scale
                  final double centerX =
                      (screenSize.width / 2) - (2500 * scale);
                  final double centerY =
                      (screenSize.height / 2) - (2500 * scale);

                  // If way off center (2000px+ instead of 1000px), trigger snapback
                  // But preserve the user's zoom level!
                  if ((x - centerX).abs() > 2000 ||
                      (y - centerY).abs() > 2000) {
                    _centerRoom(targetScale: scale);
                  }
                },
                child: Container(
                  width: 5000,
                  height: 5000,
                  color:
                      Colors.transparent, // Ensure empty space captures drags
                  alignment: Alignment.center,
                  child: RepaintBoundary(
                    // 🎨 Stop layout dirty propagation
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
                              onItemTap: (provider.isDecorating &&
                                      !provider.isFullPreviewMode)
                                  ? (item) {
                                      debugPrint(
                                          "👆 ROOM SCREEN TAPPED: ${item.name}");
                                      // Get grid coords from item
                                      int tx = 0, ty = 0;
                                      final coords =
                                          provider.getSlotCoords(item.slotType);
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
                                    }
                                  : null,
                            ),
                            // Overlay Removed - Interaction is now inside Renderer!
                          ],
                        );
                      },
                    ),
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
                onLikeTap: isVisiting
                    ? () => social.likeRoom(social.visitedUser!.id)
                    : null,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8CAA8C).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Office of: ${social.visitedUser?.displayName ?? social.visitedUser?.username ?? "Doctor"}",
                            style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (isDecorating || provider.isFullPreviewMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: SizedBox(
                    width: 240,
                    child: CozyButton(
                      label: provider.isFullPreviewMode
                          ? 'QUIT PREVIEW'
                          : 'DONE EQUIPPING',
                      variant: provider.isFullPreviewMode
                          ? CozyButtonVariant.outline
                          : CozyButtonVariant.primary,
                      onPressed: () {
                        if (provider.isFullPreviewMode) {
                          provider.toggleFullPreview(false);
                          showDialog(
                            context: context,
                            builder: (_) => ContextualShopSheet(
                              slotType: provider.lastSlotType ?? 'floor',
                              targetX: provider.lastTargetX ?? 0,
                              targetY: provider.lastTargetY ?? 0,
                            ),
                          );
                        } else {
                          provider.toggleDecorateMode();
                        }
                      },
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
  final List<ShopUserItem> placedItems;
  final Map<String, ShopUserItem?> avatarConfig;
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

  const IsometricRoom({
    super.key,
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
        ...placedItems.map((item) => _buildItem(
            item.name, item.x ?? 0, item.y ?? 0, centerX, centerY,
            isGhost: false,
            assetPath: item.assetPath,
            slotType: item.slotType)),

        // 4. Ghost Blueprints (Only visible in Decorate Mode + if category not placed + NOT VISITING)
        if (isDecorating && !social.isVisiting)
          ..._buildGhostBlueprints(context, centerX, centerY, provider),

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

  List<Widget> _buildGhostBlueprints(
      BuildContext context, double cx, double cy, ShopProvider provider) {
    // These are the "Perfect" Clinical Slots we've been tuning
    final blueprints = [
      {
        'name': 'Oak Starter Desk',
        'x': 0,
        'y': 2,
        'type': 'desk',
        'path': 'assets/images/furniture/desk_0.webp'
      },
      {
        'name': 'Modern Workstation',
        'x': 1,
        'y': 2,
        'type': 'desk_decor',
        'path': 'assets/images/furniture/computer_0.webp'
      },
      {
        'name': 'Blue Gurney',
        'x': 2,
        'y': -1,
        'type': 'exam_table',
        'path': 'assets/images/furniture/gurney_1.webp'
      },
      {
        'name': 'Geometric Wall Art',
        'x': 0,
        'y': 2,
        'type': 'wall_decor',
        'path': 'assets/images/furniture/wall_decor.webp'
      },
    ];

    debugPrint("👻 Building Ghost Blueprints: ${blueprints.length} candidates");

    return blueprints.where((bp) {
      // Hide the blueprint if a real item of this type is already placed
      return !provider.isItemTypePlaced(bp['type'] as String);
    }).map((bp) {
      debugPrint(
          "  -> Rendering Ghost: ${bp['name']} at (${bp['x']}, ${bp['y']})");
      return _buildItem(
          bp['name'] as String, bp['x'] as int, bp['y'] as int, cx, cy,
          isGhost:
              false, // buildItem handles its own logic, we'll use isBlueprint flag soon if needed
          isBlueprint: true,
          assetPath: bp['path'] as String, onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => ContextualShopSheet(
            slotType: bp['type'] as String,
            targetX: bp['x'] as int,
            targetY: bp['y'] as int,
          ),
        );
      });
    }).toList();
  }

  Widget _buildItem(
    String name,
    int gridX,
    int gridY,
    double cx,
    double cy, {
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
    } else if (slotType == 'desk_decor') {
      verticalOffset = -112; // Placed on desk surface
      horizontalOffset = -125;
    } else if (slotType == 'wall_decor') {
      verticalOffset = -160; // Placed on wall
      horizontalOffset = -125;
    }

    return Positioned(
      left: cx + screenCoords[0] + horizontalOffset,
      top: cy + screenCoords[1] + verticalOffset,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity:
              isBlueprint ? 0.4 : (isPreview ? 0.8 : (isGhost ? 0.6 : 1.0)),
          child: ItemGraphic(
              name: name,
              isGhost: isGhost,
              imagePath: assetPath,
              slotType: slotType),
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
      top: cy +
          screenCoords[1] -
          150, // Lowered to feet land on floor (was -200)
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

  // Method _buildDecorationButtons removed (unused)
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
      ..color = Colors.black.withValues(alpha: 0.15)
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

    canvas.drawPath(
        borderPath,
        Paint()
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
    super.key,
    required this.name,
    this.isGhost = false,
    this.imagePath,
    this.slotType,
  });

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
            errorBuilder: (ctx, err, stack) => Icon(
                Icons.medical_services_outlined,
                size: 60,
                color: Colors.brown[300]),
          ),
        ),
      );
    }

    // 🧱 Priority 2: Legacy Icons
    IconData iconData = Icons.chair_outlined;
    Color iconColor = const Color(0xFF6D4C41);

    if (name.contains('Table')) {
      iconData = Icons.airline_seat_flat_angled;
    } else if (name.contains('Book')) {
      iconData = Icons.menu_book;
    } else if (name.contains('Microscope')) {
      iconData = Icons.biotech;
    } else if (name.contains('Coat')) {
      iconData = Icons.checkroom;
    } else if (name.contains('Plant')) {
      iconData = Icons.eco;
      iconColor = Colors.green[800]!;
    } else if (name.contains('Espresso') || name.contains('Coffee')) {
      iconData = Icons.coffee_maker;
    } else if (name.contains('Rug')) {
      iconData = Icons.grid_view_sharp;
    }

    return Opacity(
      opacity: isGhost ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGhost
              ? Colors.grey.withValues(alpha: 0.2)
              : const Color(0xFFEFEBE9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isGhost
                ? Colors.grey.withValues(alpha: 0.4)
                : const Color(0xFF8D6E63),
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
