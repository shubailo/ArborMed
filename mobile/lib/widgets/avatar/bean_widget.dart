import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/shop_provider.dart';

class BeanWidget extends StatelessWidget {
  final Map<String, ShopUserItem?> config;
  final double size;
  final bool isWalking;
  final bool isHappy;
  final double handOffset;

  const BeanWidget({
    super.key,
    required this.config,
    this.size = 150,
    this.isWalking = false,
    this.isHappy = false,
    this.handOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Larer Order:
    // 1. Skin Color (Base)
    // 2. Body (Clothes)
    // 3. Head (Accessories)
    // 4. Hand (Tools)

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Base (Skin)
          _buildLayer(
              config['skin_color'], 'assets/skins/bean_base_default.png'),

          // 2. Body / Clothes
          if (config['body'] != null) _buildLayer(config['body'], null),

          // 3. Head
          if (config['head'] != null) _buildLayer(config['head'], null),

          // 4. Hand
          if (config['hand'] != null)
            Transform.translate(
              offset: Offset(0, handOffset),
              child: _buildLayer(config['hand'], null),
            ),
        ],
      ),
    );
  }

  Widget _buildLayer(ShopUserItem? item, String? fallbackAsset) {
    // 1. Base Layer (Skin/Hemmy)
    if (item == null && fallbackAsset != null) {
      return SvgPicture.asset(
        'assets/images/characters/hemmy.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    if (item == null) return Container();

    // 2. Mock Items (Clothes/Hats)
    return _mockRender(item);
  }

  Widget _mockRender(ShopUserItem item) {
    // Mock rendering based on item name for visual distinction without assets
    Color color = Colors.transparent;

    if (item.slotType == 'skin_color') {
      if (item.name.contains('Blue')) {
        color = Colors.blue;
      } else if (item.name.contains('Green')) {
        color = Colors.green;
      } else if (item.name.contains('Pink')) {
        color = Colors.pink;
      } else {
        color = Colors.amber;
      }

      return Container(
        width: size * 0.6,
        height: size * 0.8,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: Colors.black12, width: 2)),
        child: Center(
            child: Text("^_^\n${item.name}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8))),
      );
    } else if (item.slotType == 'body') {
      return Positioned(
          bottom: 0,
          child: Container(
            width: size * 0.6,
            height: size * 0.4,
            decoration: BoxDecoration(
                color: item.name.contains('Lab') ? Colors.white : Colors.teal,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(size * 0.3),
                    bottomRight: Radius.circular(size * 0.3))),
            child: Center(
                child: Text(item.name, style: const TextStyle(fontSize: 8))),
          ));
    } else if (item.slotType == 'head') {
      return Positioned(
          top: 0,
          child: Icon(Icons.star,
              size: size * 0.4, color: Colors.purple) // Generic Hat
          );
    }

    return Container();
  }
}
