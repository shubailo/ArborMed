import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/room/presentation/pages/room_screen.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';
import 'package:student_app/features/reward/domain/entities/reward_entities.dart';
import 'package:collection/collection.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(rewardBalanceProvider);
    final shopItemsAsync = ref.watch(shopItemsProvider);
    final inventoryAsync = ref.watch(rewardInventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB5A79E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MedBuddy Shop',
          style: TextStyle(
            color: Color(0xFF4A443F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFFB5A79E)),
            onPressed: () {
               // We need a way to navigate to RoomScreen. 
               // Importing it first or using a widget builder.
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const RoomScreen()),
               );
            },
          ),
          _BalanceBadge(balance: balance),
          const SizedBox(width: 16),
        ],
      ),
      body: shopItemsAsync.when(
        data: (items) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize Your Space',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A443F),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Earn Stethoscope points by answering questions correctly, then spend them here to customize your study space.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB5A79E),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final inventory = inventoryAsync.maybeWhen(
                      data: (inv) => inv,
                      orElse: () => <UserInventoryItem>[],
                    );
                    final ownedItem = inventory.firstWhereOrNull((i) => i.shopItemId == item.id);
                    final quantity = ownedItem?.quantity ?? 0;

                    return _ShopItemCard(item: item, ownedQuantity: quantity);
                  },
                  childCount: items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFE06C53)),
              const SizedBox(height: 16),
              const Text('Couldn’t reach the shop.'),
              TextButton(
                onPressed: () => ref.refresh(shopItemsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  final int balance;
  const _BalanceBadge({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE06C53).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE06C53).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFFE06C53)),
          const SizedBox(width: 6),
          Text(
            '$balance',
            style: const TextStyle(
              color: Color(0xFFE06C53),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends ConsumerWidget {
  final ShopItem item;
  final int ownedQuantity;
  const _ShopItemCard({required this.item, required this.ownedQuantity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 48,
                      color: const Color(0xFFB5A79E),
                    ),
                  ),
                ),
                if (ownedQuantity > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8BA989).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Owned x$ownedQuantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF4A443F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB5A79E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFFB5A79E)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: const TextStyle(
                            color: Color(0xFFE06C53),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePurchase(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BA989),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Buy', style: TextStyle(fontSize: 12)),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'room_item':
        return Icons.chair_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  void _handlePurchase(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(rewardControllerProvider).purchaseItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF8BA989),
            content: Text('Successfully purchased ${item.name}!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorMsg = e.toString();
        String displayMsg = 'Couldn’t reach the shop. Please try again.';
        
        if (errorMsg.contains('INSUFFICIENT_FUNDS')) {
          displayMsg = 'Not enough Stethoscope points to buy this item.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE06C53),
            content: Text(displayMsg),
          ),
        );
      }
    }
  }
}
