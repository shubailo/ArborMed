import 'dart:async';

import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/features/room/widgets/cozy_room_renderer.dart';
import 'package:arbor_med/features/shop/providers/shop_provider.dart';
import 'package:arbor_med/features/shop/screens/shop_screen.dart';
import 'package:arbor_med/features/shop/widgets/contextual_shop_sheet.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Shop extends ChangeNotifier implements ShopProvider {
  static final desk = ShopItem(id: 7, name: 'Test desk', type: 'furniture',
      slotType: 'desk', price: 40, assetPath: '', description: '');
  final buys = <(int, int?)>[];
  Completer<bool>? pendingBuy;
  @override
  List<ShopItem> get catalog => [desk];
  @override
  List<ShopUserItem> get inventory => [];
  @override
  List<ShopItem> get equippedItemsAsShopItems => [];
  @override
  ShopItem get currentRoom => desk;
  @override
  bool get isLoading => false;
  @override
  bool get isFullPreviewMode => false;
  @override
  String? get errorMessage => null;
  @override
  Future<void> fetchCatalog({String? slotType, String? theme}) async {}
  @override
  Future<void> fetchInventory({bool notify = true}) async {}
  @override
  void setPreviewItem(ShopItem? item, {int? x, int? y}) {}
  @override
  Future<bool> buyItem(int itemId, BuildContext context, {int? expectedPrice}) async {
    buys.add((itemId, expectedPrice));
    final pending = pendingBuy;
    return pending == null ? true : await pending.future;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  int sessionRevision = 0;
  @override
  User get user => User.fromJson({'id': 1, 'coins': 100});
  @override
  Future<void> refreshUser() async => throw StateError('Offline');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  Future<void> playSfx(String name) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('same-category furniture at the grid origin and a second cell both render', (tester) async {
    ShopItem asset(int id, String slot, [(int, int)? cell]) => ShopItem(
        id:id, name:'Item', type:'furniture', slotType:slot, price:0,
        assetPath:'assets/images/furniture/desk_0.webp', description:'', gridCell:cell);
    await tester.pumpWidget(MaterialApp(home: CozyRoomRenderer(
      room: asset(1,'room'), equippedItems:[asset(2,'desk'),asset(3,'desk',(0,0)),asset(4,'desk',(1,0))],
    )));
    Transform placement(int id) => tester.widget(find.byKey(ValueKey('E_desk_${id}_')));
    expect(placement(2).transform.getTranslation().x, 0);
    expect(placement(3).transform.getTranslation().x, 0);
    expect(placement(4).transform.getTranslation().x, 30);
    expect(placement(4).transform.getTranslation().y, 15);
  });

  testWidgets('a contextual purchase stops when the original session ends', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final shop = _Shop()..pendingBuy = Completer<bool>();
    final auth = _Auth();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ShopProvider>.value(value: shop),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MaterialApp(home: Scaffold(body: ContextualShopSheet(slotType:'desk',targetX:0,targetY:0))),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(SmartItemIcon).first);
    await tester.pump();
    tester.widget<CozyButton>(find.byWidgetPredicate(
        (widget) => widget is CozyButton && widget.label.startsWith('Buy & Equip'))).onPressed!();
    auth.sessionRevision++;
    shop.pendingBuy!.complete(true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(shop.buys, [(7,40)]);
    expect(tester.takeException(), isNull);
    expect(find.byType(ContextualShopSheet), findsOneWidget);
  });

  testWidgets('confirmation belongs to its original session and balance refresh can fail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final shop = _Shop(), auth = _Auth();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ShopProvider>.value(value: shop),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MaterialApp(home: Scaffold(body: ShopScreen())),
    ));
    Future<void> frames() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await frames();
    void begin() => tester.widget<CozyButton>(
        find.widgetWithText(CozyButton, '40 🩺')).onPressed!();
    begin();
    begin();
    await frames();
    auth.sessionRevision++;
    await tester.tap(find.text('CONFIRM'));
    await frames();
    expect(find.text('CONFIRM'), findsNothing);
    expect(shop.buys, isEmpty);
    begin();
    await frames();
    await tester.tap(find.text('CONFIRM'));
    await frames();
    expect(shop.buys, [(7, 40)]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
