import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
import '../../models/user.dart';

class StatusHud extends StatelessWidget {
  final User user;

  const StatusHud({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Left Status Row
            Row(
              children: [
                _buildStatusTag(
                  icon: Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 22, height: 22),
                  value: '${user.coins}',
                  borderColor: CozyTheme.primary,
                ),
                const SizedBox(width: 12),
                _buildStatusTag(
                  icon: const Icon(Icons.local_fire_department_rounded, color: CozyTheme.accent, size: 24),
                  value: '${user.streakCount}',
                  borderColor: CozyTheme.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag({required Widget icon, required String value, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CozyTheme.paperWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 3))
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            value,
            style: CozyTheme.textTheme.titleMedium?.copyWith(
              color: CozyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
