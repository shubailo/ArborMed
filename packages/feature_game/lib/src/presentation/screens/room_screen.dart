import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../services/furniture_service.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late FurnitureService _furnitureService;

  @override
  void initState() {
    super.initState();
    _furnitureService = GetIt.I<FurnitureService>();
    _furnitureService.loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);

    return ChangeNotifierProvider.value(
      value: _furnitureService,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'My ArborRoom',
            style: theme.textTheme.titleMedium.copyWith(color: theme.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // Room Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.grid_4x4, size: 200, color: theme.primary),
              ),
            ),
            
            // Placed Items
            Consumer<FurnitureService>(
              builder: (context, service, child) {
                final placedItems = service.items.where((i) => i.isPlaced).toList();
                
                return Stack(
                  children: placedItems.map((item) {
                    return Positioned(
                      left: item.x,
                      top: item.y,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          service.updatePosition(
                            item.slug,
                            item.x + details.delta.dx,
                            item.y + details.delta.dy,
                          );
                        },
                        child: _buildFurnitureItem(item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showShop(context),
          backgroundColor: theme.primary,
          child: const Icon(Icons.shopping_basket, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFurnitureItem(item) {
    return Column(
      children: [
        Icon(Icons.chair, size: 40, color: Colors.brown), // Dynamic assetPath later
        Text(item.nameEn, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _showShop(BuildContext context) {
    // For now, just a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Furniture Shop...')),
    );
  }
}
