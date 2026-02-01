import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/avatar/bean_widget.dart';
import '../../services/shop_provider.dart'; // For avatar config

class QuizLoadingScreen extends StatefulWidget {
  final String systemName;
  final VoidCallback onAnimationComplete;

  const QuizLoadingScreen({super.key, required this.systemName, required this.onAnimationComplete});

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading/animation time
    Future.delayed(const Duration(seconds: 3), () {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatarConfig = Provider.of<ShopProvider>(context, listen: false).avatarConfig;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F4), // Clinical Blue-White
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hemmy "Dressing Up" Animation Placeholder
            SizedBox(
              width: 150,
              height: 150,
              child: BeanWidget(
                config: avatarConfig, 
                size: 150, 
                isWalking: false, 
                isHappy: true,
                handOffset: -5, // Saluting?
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "PREPARING ${widget.systemName.toUpperCase()}...",
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF006064), 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.black12,
                color: Colors.tealAccent[700],
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Text("Hemmy is putting on his scrubs...", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
