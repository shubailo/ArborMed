import 'package:flutter/material.dart';

class AdminPhonePreview extends StatelessWidget {
  final Widget child;

  const AdminPhonePreview({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Provide a "canonical" size for FittedBox to scale from.
    // 320 / 675 is approximately 9/19 ratio.
    return SizedBox(
      width: 320,
      height: 675,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade800, width: 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: const Color(0xFFFFFDF5), // App background color
            child: Column(
              children: [
                // Status Bar Simulation
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("9:41", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: const [
                          Icon(Icons.signal_cellular_4_bar, size: 12),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, size: 12),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full, size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                // App Bar Simulation
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, size: 20),
                      const SizedBox(width: 16),
                      const Text("Quiz Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: child,
                ),
                // Bottom Indicator
                Container(
                  height: 20,
                  alignment: Alignment.center,
                  child: Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
