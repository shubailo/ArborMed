import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/ui/cozy_modal_scaffold.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';
import 'package:student_app/features/reward/domain/entities/reward_entities.dart';

class DecorateShopModal extends ConsumerStatefulWidget {
  const DecorateShopModal({super.key});

  @override
  ConsumerState<DecorateShopModal> createState() => _DecorateShopModalState();
}

class _DecorateShopModalState extends ConsumerState<DecorateShopModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CozyModalScaffold(
      title: 'Clinic Decor',
      action: _BalanceBadge(),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.sageGreen,
            unselectedLabelColor: AppTheme.warmBrown.withValues(alpha: 0.5),
            indicatorColor: AppTheme.sageGreen,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'My Items'),
              Tab(text: 'Shop'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: TabBarView(
              controller: _tabController,
              children: [_InventoryTab(), _ShopTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(rewardBalanceProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen.withValues(alpha: 0.1),
        borderRadius: CozyTheme.borderMedium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 16,
            color: AppTheme.sageGreen,
          ),
          const SizedBox(width: 6),
          Text(
            '$balance',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.sageGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(rewardInventoryProvider);

    return inventory.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState('No items yet. Visit the shop!');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _InventoryItemCard(item: items[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading inventory')),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final UserInventoryItem item;
  const _InventoryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: CozyTheme.borderMedium,
        boxShadow: CozyTheme.panelShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 48, color: Colors.black12),
          const SizedBox(height: 12),
          Text(
            item.shopItem?.name ?? 'Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Quantity: ${item.quantity}',
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap slot to place',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.sageGreen,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopItems = ref.watch(shopItemsProvider);

    return shopItems.when(
      data: (items) => GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _ShopItemCard(item: items[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading shop')),
    );
  }
}

class _ShopItemCard extends ConsumerWidget {
  final ShopItem item;
  const _ShopItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: CozyTheme.borderMedium,
        boxShadow: CozyTheme.panelShadow,
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppTheme.softClay.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        color: AppTheme.softClay,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _BuyButton(item: item),
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

class _BuyButton extends ConsumerStatefulWidget {
  final ShopItem item;
  const _BuyButton({required this.item});

  @override
  ConsumerState<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends ConsumerState<_BuyButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _handleBuy,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: CozyTheme.borderSmall),
      ),
      child: _loading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Buy', style: TextStyle(fontSize: 12)),
    );
  }

  void _handleBuy() async {
    setState(() => _loading = true);
    try {
      await ref.read(rewardControllerProvider).purchaseItem(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${widget.item.name}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Purchase failed.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
