import 'package:go_router/go_router.dart';
import 'screens/room_screen.dart';

class GameRoutes {
  static const String room = '/arbor-room';

  static List<RouteBase> get routes => [
    GoRoute(
      path: room,
      builder: (context, state) => const RoomScreen(),
    ),
  ];
}
