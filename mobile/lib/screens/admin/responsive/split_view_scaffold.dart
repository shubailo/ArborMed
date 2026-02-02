import 'package:flutter/material.dart';

class SplitViewScaffold extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget? emptyDetail;
  final String title;
  final List<Widget>? actions;

  const SplitViewScaffold({
    super.key,
    required this.master,
    this.detail,
    this.emptyDetail,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Desktop: Master-Detail
          return Scaffold(
             appBar: AppBar(
              title: Text(title),
              actions: actions,
              scrolledUnderElevation: 0,
            ),
            body: Row(
              children: [
                SizedBox(
                  width: 350, // Fixed width for master list
                  child: master,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: detail ?? emptyDetail ?? const Center(child: Text("Select an item")),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Master Only (Detail is handled via navigation push)
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: actions,
            ),
            body: master,
          );
        }
      },
    );
  }
}
