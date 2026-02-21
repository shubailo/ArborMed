import 'package:flutter/material.dart';

class StudyTopBar extends StatelessWidget {
  const StudyTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Match background
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF1EFE7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: Color(0xFFB5A79E),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '5', // Hook up later
                      style: TextStyle(
                        color: Color(0xFFE06C53), // Soft red/orange
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Close Button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF1EFE7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFB5A79E),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.2, // Wire to real session progress later
              backgroundColor: Color(0xFFF1EFE7),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2DDD1)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
