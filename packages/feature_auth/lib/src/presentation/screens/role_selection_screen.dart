import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ArborMed',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Choose your path',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 64),
              
              _RoleButton(
                title: 'Medical Student',
                icon: Icons.school_rounded,
                onTap: () => context.push('/login/student'),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                title: 'Administrator',
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => context.push('/login/admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: theme.paperWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: theme.shadowSmall,
          border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}
