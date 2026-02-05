import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Watch auth state
    final auth = Provider.of<AuthProvider>(context);
    
    if (!auth.isAuthenticated) {
       // Not logged in -> Redirect executed next frame
       Future.microtask(() {
         if (context.mounted) {
           Navigator.pushReplacementNamed(context, '/login');
         }
       });
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.user?.role != 'admin') {
      return Scaffold(
        backgroundColor: CozyTheme.of(context).background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Access Denied",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary),
              ),
              const SizedBox(height: 8),
              Text("Teachers only area.", style: TextStyle(color: CozyTheme.of(context).textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary,
                  foregroundColor: Colors.white
                ),
                child: const Text("Back to Class"),
              )
            ],
          ),
        ),
      );
    }

    // Access Granted
    return child;
  }
}
