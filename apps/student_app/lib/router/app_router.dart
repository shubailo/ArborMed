import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';

class AppRouter {
  static GoRouter createRouter(
    List<RouteBase> featureRoutes,
    AuthContract authService,
  ) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authService.authStateStream),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        ...featureRoutes, // Plug-in federated routes from all registered features
      ],
      redirect: (context, state) {
        final authState = authService.authState;
        final path = state.uri.path;
        final isAuthPath = path.startsWith('/auth') || 
                          path.startsWith('/login') || 
                          path.startsWith('/register') || 
                          path.startsWith('/verify');

        debugPrint("[Router] Redirect check: path=${state.uri.toString()} state=$authState role=${authService.userRole}");

        // 1. Initial Loading (Splash)
        if (authState == AuthState.loading) {
          if (state.uri.toString() == '/') {
            debugPrint("[Router] -> Staying on Splash (Initial Loading)");
            return null;
          }
          debugPrint("[Router] -> Staying on current page during Loading (Potential action in progress)");
          return null;
        }

        // 2. Unauthenticated -> Force to /auth
        if (authState == AuthState.unauthenticated) {
          if (isAuthPath) {
            debugPrint("[Router] -> Staying on Auth path");
            return null;
          }
          debugPrint("[Router] -> Redirecting to /auth (Unauthenticated)");
          return '/auth';
        }

        // 3. Authenticated -> Don't stay in /auth or / (Splash)
        if (authState == AuthState.authenticated) {
          if (isAuthPath || state.uri.toString() == '/') {
            // Role branching
            final target = authService.userRole == 'admin' ? '/admin/dashboard' : '/dashboard';
            debugPrint("[Router] -> Redirecting to $target (Authenticated)");
            return target;
          }
        }

        debugPrint("[Router] -> No redirect needed");
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
