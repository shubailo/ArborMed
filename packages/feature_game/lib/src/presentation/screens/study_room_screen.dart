import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';
import '../../services/game_service.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final game = GetIt.I<GameContract>() as GameService;

    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        if (game.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: theme.background,
          body: Stack(
            children: [
              // 1. Room Background (Bottom Layer)
              _buildBackground(context),

              // 2. Interactive Furniture Slots
              _buildFurnitureLayer(context, game),

              // 3. UI Overlay (Top Layer)
              _buildOverlay(context, game),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showInventory(context, game),
            backgroundColor: theme.primary,
            icon: const Icon(Icons.inventory_2, color: Colors.white),
            label: const Text('Edit Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'packages/core/assets/images/room/room_0.webp',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFurnitureLayer(BuildContext context, GameService game) {
    // Define normalized slots (x, y are 0.0 to 1.0)
    // Legacy room geometry: Desk in center-bottom, Bed on left, Cabinet on right.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // RUG (Bottom-most)
            _buildSlot(context, game, 'rug', left: w * 0.2, top: h * 0.65, width: w * 0.6),
            
            // EXAM TABLE
            _buildSlot(context, game, 'exam_table', left: w * 0.05, top: h * 0.45, width: w * 0.4),

            // DESK
            _buildSlot(context, game, 'desk', left: w * 0.5, top: h * 0.45, width: w * 0.45),

            // CORNER CABINET
            _buildSlot(context, game, 'corner_cabinet', left: w * 0.75, top: h * 0.25, width: w * 0.2),
          ],
        );
      },
    );
  }

  Widget _buildSlot(BuildContext context, GameService game, String slotId, {required double left, required double top, required double width}) {
    final itemId = game.currentLayout[slotId];
    final item = itemId != null ? game.ownedItems.firstWhere((i) => i.id == itemId, orElse: () => game.catalog.firstWhere((cat) => cat.id == itemId)) : null;

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: item != null 
          ? Image.asset(
              'packages/core/${item.assetPath}', 
              key: ValueKey(item.id),
              fit: BoxFit.contain,
            )
          : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, GameService game) {
    final theme = CozyTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                child: Icon(Icons.arrow_back, color: theme.primary),
              ),
            ),
            _buildCoinBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinBadge(BuildContext context) {
    final theme = CozyTheme.of(context);
    final student = GetIt.I<StudentContract>();
    
    return FutureBuilder<int>(
      future: student.getCoins(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                '${snapshot.data ?? 0}',
                style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showInventory(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _InventoryBottomSheet(game: game),
    );
  }
}

class _InventoryBottomSheet extends StatelessWidget {
  final GameService game;
  const _InventoryBottomSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text('Your Inventory', style: theme.headingSmall),
               TextButton(
                 onPressed: () => GetIt.I<NavigationContract>().navigateTo('/shop'),
                 child: const Text('Go to Shop'),
               ),
             ],
           ),
           const SizedBox(height: 16),
           Expanded(
             child: game.ownedItems.isEmpty 
              ? const Center(child: Text('No furniture owned yet.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: game.ownedItems.length,
                  itemBuilder: (context, index) {
                    final item = game.ownedItems[index];
                    return GestureDetector(
                      onTap: () {
                        final layout = Map<String, String>.from(game.currentLayout);
                        layout[item.slotType] = item.id;
                        game.saveRoomLayout(layout);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.paperWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: Image.asset('packages/core/${item.assetPath}')),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(item.name, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
           ),
        ],
      ),
    );
  }
}
