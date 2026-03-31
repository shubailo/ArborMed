import 'package:flutter/material.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_quiz/feature_quiz.dart';
import 'package:feature_student/feature_student.dart';
import 'package:feature_game/feature_game.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_auth/src/presentation/auth_routes.dart';

class AppRouter {
  static GoRouter createRouter(List<RouteBase> featureRoutes) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()), // Splash/Initial state
          ),
        ),
        ...AuthRoutes.routes, // Plug-in Auth
        ...QuizRoutes.routes, // Plug-in Quiz
        ...StudentRoutes.routes, // Plug-in Student
        ...GameRoutes.routes, // Plug-in Game
        ...featureRoutes, // Plug-in routes from other features
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
