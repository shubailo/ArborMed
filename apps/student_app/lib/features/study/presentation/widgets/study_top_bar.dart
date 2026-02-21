import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';
import 'package:student_app/features/reward/presentation/pages/shop_screen.dart';
import 'package:student_app/features/progress/presentation/pages/progress_screen.dart';

class StudyTopBar extends ConsumerWidget {
  const StudyTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(rewardBalanceProvider);
    final fetcher = ref.watch(rewardBalanceFetcherProvider);

    return fetcher.when(
      loading: () => _buildTopBar(context, ref, '...', isLoading: true),
      error: (err, stack) => _buildTopBar(context, ref, '!', isError: true),
      data: (_) => _buildTopBar(context, ref, '$balance'),
    );
  }

  Widget _buildTopBar(
    BuildContext context, 
    WidgetRef ref, 
    String balanceText, {
    bool isLoading = false,
    bool isError = false,
  }) {
    return Container(
      color: Colors.white, // Match background
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score Pill
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShopScreen()),
                  );
                },
                child: Container(
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xFFB5A79E),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      if (isLoading)
                         const SizedBox(
                           width: 12,
                           height: 12,
                           child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE06C53)),
                         )
                      else if (isError)
                         GestureDetector(
                           onTap: () => ref.invalidate(rewardBalanceFetcherProvider),
                           child: const Icon(Icons.refresh, size: 14, color: Color(0xFFE06C53)),
                         )
                      else
                        Text(
                          balanceText, 
                          style: const TextStyle(
                            color: Color(0xFFE06C53),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Progress Icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressScreen()),
                  );
                },
                child: Container(
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
                    Icons.bar_chart_outlined,
                    color: Color(0xFFB5A79E),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
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
