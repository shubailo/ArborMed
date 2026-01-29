import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_button.dart';

class FeedbackBottomSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;

  const FeedbackBottomSheet({
    Key? key,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎨 dynamic styling based on result
    final color = isCorrect 
        ? const Color(0xFF58CC02) // Duolingo Green
        : const Color(0xFFFF4B4B); // Duolingo Red
    
    final lightColor = isCorrect
        ? const Color(0xFFD7FFB8)
        : const Color(0xFFFFDFE0);

    final title = isCorrect ? "Correct!" : "Incorrect Answer";
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      color: Colors.transparent, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Reduced vertical padding
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)), // Duolingo is flat or slight, let's keep it clean
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
            children: [
              // 1. Icon (Left)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: Colors.white,
                ),
                child: Icon(icon, color: color, size: 36), // Slightly larger icon, white background
              ),
              const SizedBox(width: 16),
              
              // 2. Text Content (Expanded Middle)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 18, // Smaller than before
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    if (!isCorrect && explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        explanation,
                        style: TextStyle(
                          fontSize: 14,
                          color: color, // Duolingo uses the theme color for the explanation text too usually
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 16),

              // 3. Compact Continue Button (Right)
              SizedBox(
                width: 120, // Check Duolingo width, this is a reasonable compact width
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, // Button matches feedback color
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onContinue,
                  child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
