import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';
import '../../services/game_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final game = GetIt.I<GameContract>() as GameService;

    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final filteredCatalog = _selectedCategory == 'all' 
          ? game.catalog 
          : game.catalog.where((i) => i.slotType == _selectedCategory).toList();

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            title: Text('ArborShop', style: theme.headingSmall.copyWith(color: theme.primary)),
            leading: IconButton(
              icon: Icon(Icons.close, color: theme.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _buildCoinBadge(context),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryTabs(context),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredCatalog.length,
                  itemBuilder: (context, index) {
                    final item = filteredCatalog[index];
                    final isOwned = game.ownedItems.any((oi) => oi.id == item.id);
                    return _buildShopItem(context, game, item, isOwned);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinBadge(BuildContext context) {
    final theme = CozyTheme.of(context);
    final student = GetIt.I<StudentContract>();
    
    return FutureBuilder<int>(
      future: student.getCoins(),
      builder: (context, snapshot) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${snapshot.data ?? 0}',
                  style: theme.bodyMedium.copyWith(color: Colors.orange[800], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
     final categories = ['all', 'desk', 'exam_table', 'corner_cabinet', 'rug'];
     final theme = CozyTheme.of(context);

     return SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       child: Row(
         children: categories.map((cat) {
           final isSelected = _selectedCategory == cat;
           return Padding(
             padding: const EdgeInsets.only(right: 8.0),
             child: ChoiceChip(
               label: Text(cat.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : theme.textSecondary)),
               selected: isSelected,
               selectedColor: theme.primary,
               backgroundColor: theme.paperWhite,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
               onSelected: (selected) {
                 if (selected) setState(() => _selectedCategory = cat);
               },
             ),
           );
         }).toList(),
       ),
     );
  }

  Widget _buildShopItem(BuildContext context, GameService game, FurnitureItem item, bool isOwned) {
    final theme = CozyTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: theme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Hero(
                tag: 'item_${item.id}',
                child: Image.asset('packages/core/${item.assetPath}', fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isOwned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('OWNED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text('${item.price}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
                        ],
                      ),
                    
                    if (!isOwned)
                      IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(backgroundColor: theme.primary),
                        onPressed: () async {
                           final success = await game.purchaseItem(item.id);
                           if (!mounted) return;
                           if (success) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased ${item.name}!')));
                             setState(() {}); // Refresh local state
                           } else {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient coins!')));
                           }
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
