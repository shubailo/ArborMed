import 'package:go_router/go_router.dart';
import 'screens/study_room_screen.dart';
import 'screens/shop_screen.dart';

class GameRoutes {
  static const String room = '/room';
  static const String shop = '/shop';

  static List<RouteBase> get routes => [
    GoRoute(
      path: room,
      builder: (context, state) => const StudyRoomScreen(),
    ),
    GoRoute(
      path: shop,
      builder: (context, state) => const ShopScreen(),
    ),
  ];
}
