import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../theme/cozy_theme.dart';

class DashboardMasonry extends StatelessWidget {
  final List<Widget> tiles;

  const DashboardMasonry({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2; // Mobile
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4; // Large Desktop
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3; // Tablet/Small Desktop
        }

        return StaggeredGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: tiles,
        );
      },
    );
  }
}

class KpiTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const KpiTile({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).paperWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: CozyTheme.of(context).shadowSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CozyTheme.of(context).primary, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class WidgetTile extends StatelessWidget {
  final Widget child;
  final int crossAxisCellCount;
  final int mainAxisCellCount;

  const WidgetTile({
    super.key, 
    required this.child, 
    this.crossAxisCellCount = 2, 
    this.mainAxisCellCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: mainAxisCellCount,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).paperWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: CozyTheme.of(context).shadowSmall,
        ),
        child: child,
      ),
    );
  }
}
