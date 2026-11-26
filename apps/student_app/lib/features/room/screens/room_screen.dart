import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Core & Providers
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/profile/providers/rank_provider.dart';
import 'package:arbor_med/features/shop/providers/shop_provider.dart';
import 'package:arbor_med/features/social/providers/social_provider.dart';
import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
import 'package:arbor_med/theme/cozy_theme.dart';

// Feature Widgets
import '../widgets/room_camera.dart';
import '../widgets/hub/cozy_actions_overlay.dart';
import '../widgets/probation_overlay.dart';
import '../widgets/cozy_room_renderer.dart';
import '../widgets/hub/settings_sheet.dart';
import '../../profile/widgets/profile_portal.dart';
import '../../social/widgets/clinic_directory_sheet.dart';
import '../../dashboard/widgets/mission_control_view.dart';
import '../../shop/screens/shop_screen.dart';
import '../../shop/widgets/contextual_shop_sheet.dart';
import '../../quiz/widgets/quiz_portal.dart';
import '../../quiz/widgets/quiz_menu.dart';
import '../../quiz/screens/quiz_loading_screen.dart';
import '../../quiz/screens/quiz_session_screen.dart';
import '../../../widgets/cozy/cozy_button.dart';
import '../../../widgets/cozy/floating_medical_icons.dart';
import '../../../screens/game/duel_lobby_screen.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RoomWidget(),
    );
  }
}

class RoomWidget extends StatefulWidget {
  const RoomWidget({super.key});

  @override
  createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final RoomCamera _camera;
  bool _isZoomed = false;

  @override
  void dispose() {
    _camera.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _transformationController = TransformationController(
      Matrix4.translationValues(-1000.0, -1000.0, 0.0)
        ..scaleByDouble(0.4, 0.4, 1.0, 1.0),
    );

    _camera = RoomCamera(_transformationController, this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shop = Provider.of<ShopProvider>(context, listen: false);
      final stats = Provider.of<StatsProvider>(context, listen: false);
      final audio = Provider.of<AudioProvider>(context, listen: false);

      final auth = Provider.of<AuthProvider>(context, listen: false);

      Future.wait([
        shop.fetchInventory(),
        stats.preFetchData(),
        auth.refreshUser(),
      ]).catchError((e) {
        debugPrint("Background fetch error: $e");
        return [];
      });

      audio.fadeIn();

      _startCinematicEntry();
    });
  }

  void _startCinematicEntry() {
    if (!mounted) return;
    final Size screenSize = MediaQuery.of(context).size;

    if (screenSize.width <= 0 || screenSize.height <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCinematicEntry());
      return;
    }

    const double finalScale = 0.4;
    const double startScale = 0.2;

    final double endX = (screenSize.width / 2) - (2500 * finalScale);
    final double endY = (screenSize.height / 2) - (2500 * finalScale);

    final double startX = (screenSize.width / 2) - (2500 * startScale);
    final double startY = (screenSize.height / 2) - (2500 * startScale);

    _transformationController.value = Matrix4.translationValues(startX, startY, 0)
      ..scaleByDouble(startScale, startScale, 1, 1);
    _camera.animateTo(
      Matrix4.translationValues(endX, endY, 0)..scaleByDouble(finalScale, finalScale, 1, 1),
      const Duration(milliseconds: 900),
      curve: Curves.easeOutQuart,
    );
  }

  void _centerRoom({bool animate = true, double? targetScale}) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scale = targetScale ?? 0.4;

    final double targetX = (screenSize.width / 2) - (2500 * scale);
    final double targetY = (screenSize.height / 2) - (2500 * scale);

    final Matrix4 endValue = Matrix4.translationValues(targetX, targetY, 0.0)..scaleByDouble(scale, scale, 1, 1);

    if (animate) {
      _camera.animateTo(endValue, const Duration(seconds: 1));
    } else {
      _transformationController.value = endValue;
    }
  }

  void _zoomToDesk() {
    final Size screenSize = MediaQuery.of(context).size;
    const double zoomScale = 1.0;

    final double targetX = (screenSize.width / 2) - (2500 * zoomScale);
    final double targetY = (screenSize.height / 2) - (2200 * zoomScale);

    final Matrix4 zoomMatrix = Matrix4.translationValues(targetX, targetY - 200, 0.0)..scaleByDouble(zoomScale, zoomScale, 1, 1);

    setState(() => _isZoomed = true);
    _camera.animateTo(zoomMatrix, const Duration(milliseconds: 1200));
  }

  void _resetFromZoom() {
    setState(() => _isZoomed = false);
    _centerRoom(animate: true);
  }

  void _openQuizPortal() {
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
              Navigator.pop(context);
              _startQuizSequence(name, slug);
            },
          ),
        );
      },
    );
  }

  Future<void> _startQuizSequence(String name, String slug) async {
    final auth = context.read<AuthProvider>();
    final owner = auth.user?.id;
    final session = auth.sessionRevision;
    if (owner == null) return;
    final finished = await openRoomQuiz(context, name, slug, owner);
    if (!mounted || !finished || auth.user?.id != owner || auth.sessionRevision != session) return;
    _centerRoom();
    final stats = context.read<StatsProvider>();
    try {
      await Future.wait([
        context.read<RankProvider>().fetchStatus(),
        auth.refreshUser(),
        stats.fetchSummary(),
        stats.fetchActivity(),
        stats.fetchSubjectDetail(slug),
        stats.fetchSmartReview(),
        stats.fetchReadiness(),
      ]);
    } catch (error) {
      debugPrint('Quiz return refresh failed: ${error.runtimeType}');
    }
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
            Navigator.pop(context);
            _startQuizSequence(name, slug);
          },
        );
      },
    );
  }

  void _showSettings() {
    showDialog(context: context, builder: (_) => const SettingsSheet());
  }

  void _openShop() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ShopScreen',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return const ShopScreen();
      },
    );
  }

  void _openDuel() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DuelLobbyScreen()),
    );
  }

  void _showLeaveNoteDialog(User colleague) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFDF5),
        title: Text(
          "Consultation for ${colleague.username}",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Leave a helpful observation...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<SocialProvider>(context, listen: false)
                    .leaveNote(colleague.id, noteController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note left in the records!")),
                );
              } catch (e) {
                if (!context.mounted) return;
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

  Color _getAmbientOverlay() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return const Color(0xFFF5D78E).withValues(alpha: 0.08);
    if (hour >= 12 && hour < 18) return Colors.transparent;
    if (hour >= 18 && hour < 21) return const Color(0xFFE8A87C).withValues(alpha: 0.10);
    return const Color(0xFF7B9EC8).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final social = Provider.of<SocialProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    final rankProvider = Provider.of<RankProvider>(context);

    final isDecorating = provider.isDecorating;
    final isVisiting = social.isVisiting;
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          Provider.of<AudioProvider>(context, listen: false).resumeOnInteraction();
        },
        child: Container(
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
              Positioned.fill(
                child: FloatingMedicalIcons(color: CozyTheme.of(context).primary),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: _getAmbientOverlay()),
                ),
              ),
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panAxis: PanAxis.free,
                  onInteractionStart: (_) => _camera.stop(),
                  boundaryMargin: const EdgeInsets.all(5000),
                  minScale: 0.1,
                  maxScale: 2.0,
                  constrained: false,
                  onInteractionEnd: (details) {
                    final matrix = _transformationController.value;
                    final x = matrix.getTranslation().x;
                    final y = matrix.getTranslation().y;
                    final scale = matrix.getMaxScaleOnAxis();
                    final Size screenSize = MediaQuery.of(context).size;
                    final double centerX = (screenSize.width / 2) - (2500 * scale);
                    final double centerY = (screenSize.height / 2) - (2500 * scale);

                    if ((x - centerX).abs() > 2000 || (y - centerY).abs() > 2000) {
                      _centerRoom(targetScale: scale);
                    }
                  },
                  child: Container(
                    width: 5000,
                    height: 5000,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: RepaintBoundary(
                      child: Consumer2<ShopProvider, SocialProvider>(
                        builder: (context, provider, social, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              CozyRoomRenderer(
                                room: provider.currentRoom,
                                equippedItems: provider.equippedItemsAsShopItems,
                                borderRadius: BorderRadius.circular(20),
                                ghostItems: provider.getGhostItems(),
                                previewItem: provider.previewItem,
                                onItemTap: (item) {
                                  if (provider.isDecorating && !provider.isFullPreviewMode) {
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
                                  } else if (!provider.isDecorating && !social.isVisiting) {
                                    if (item.slotType == 'desk' || item.slotType == 'desk_decor') {
                                      _zoomToDesk();
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (_isZoomed)
                Positioned.fill(
                  child: MissionControlView(
                    onBack: _resetFromZoom,
                    onStartRounds: () {
                      _resetFromZoom();
                      _openQuizPortal();
                    },
                  ),
                ),
              if (!isDecorating && !provider.isFullPreviewMode && !_isZoomed)
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
                  onShopTap: _openShop,
                  onDuelTap: _openDuel,
                  onCenterRoomTap: () => _centerRoom(animate: true),
                  onRoundsTap: _zoomToDesk,
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
              if (rankProvider.isOnProbation && !rankProvider.hasDoneRoundsToday && !isVisiting)
                Positioned.fill(
                  child: ProbationOverlay(
                    onStartRounds: _openQuizPortal,
                  ),
                ),
              if (isVisiting)
                Positioned(
                  top: 100,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A4A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Office of: ${social.visitedUser?.displayName ?? social.visitedUser?.username ?? "Doctor"}",
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isDecorating && !provider.isFullPreviewMode)
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: CozyTheme.of(context).paperWhite.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: CozyTheme.of(context).shadowSmall,
                        border: Border.all(
                          color: CozyTheme.of(context).primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, color: CozyTheme.of(context).primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isHu
                                ? 'Koppints a kijelölt helyekre a berendezéshez és vásárláshoz!'
                                : 'Tap highlighted areas to purchase & place equipment!',
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isDecorating || provider.isFullPreviewMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: SizedBox(
                      width: 260,
                      child: CozyButton(
                        label: provider.isFullPreviewMode
                            ? (isHu ? 'ELŐNÉZET BEZÁRÁSA' : 'QUIT PREVIEW')
                            : (isHu ? 'BERENDEZÉS KÉSZ' : 'DONE EQUIPPING'),
                        variant: provider.isFullPreviewMode ? CozyButtonVariant.outline : CozyButtonVariant.primary,
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
      ),
    );
  }
}

/// Keep the loading view and the quiz on one route, including when a dialog covers it.
Future<bool> openRoomQuiz(BuildContext context, String name, String slug, int owner) async {
  final api = context.read<AuthProvider>().apiService;
  if (api.userId != owner) return false;
  final selection = context.read<QuestionCacheService>().open(slug);
  Future<Map<String, dynamic>> load() async {
    selection.prefetch();
    var sessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final session = await api.post('/quiz/start', {});
      if (session is Map && session['id'] != null) sessionId = session['id'].toString();
    } catch (error) {
      debugPrint('Quiz session handshake failed: ${error.runtimeType}');
    }
    final question = await selection.next(prefetchNext: false);
    return {'question': question, 'sessionId': sessionId};
  }

  final future = load();
  // A fast response can fail before Navigator builds the first frame.
  future.ignore();
  Map<String, dynamic>? result;
  try {
    await Navigator.of(context).push<void>(PageRouteBuilder(
      pageBuilder: (_, animation, secondaryAnimation) => StatefulBuilder(
        builder: (routeContext, rebuild) {
          final data = result;
          if (data != null) {
            return QuizSessionScreen(
              ownerId: owner,
              systemName: name,
              systemSlug: slug,
              initialData: data['question'],
              sessionId: data['sessionId'],
            );
          }
          return QuizLoadingScreen(
            systemName: name, dataFuture: future,
            onComplete: (value) {
              final route = ModalRoute.of(routeContext);
              if (route == null || !route.isActive) return;
              if (!selection.isActive) {
                Navigator.of(routeContext).removeRoute(route);
                return;
              }
              rebuild(() => result = value);
            },
          );
        },
      ),
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
    return result != null;
  } finally {
    selection.close();
  }
}
