import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Animated budget progress bar with gradient fill
class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    if (budget <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textDimmed, size: 18),
            SizedBox(width: 10),
            Text(
              "Set a budget to see your progress",
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final percent = (spent / budget).clamp(0.0, 1.5);
    final displayPercent = (percent * 100).toInt();
    final remaining = budget - spent;
    final isOver = remaining < 0;

    // Color logic: green → orange → red
    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (percent <= 0.5) {
      statusColor = const Color(0xFF22C55E);
      statusText = "On Track 👍";
      statusIcon = Icons.check_circle_outline;
    } else if (percent <= 0.8) {
      statusColor = const Color(0xFFFBBF24);
      statusText = "Moderate ⚡";
      statusIcon = Icons.warning_amber_rounded;
    } else if (percent <= 1.0) {
      statusColor = AppColors.orange;
      statusText = "Almost There 🔥";
      statusIcon = Icons.local_fire_department_outlined;
    } else {
      statusColor = AppColors.pinkRed;
      statusText = "Over Budget! 🚨";
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                "$displayPercent%",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  color: AppColors.darkInput,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  width: MediaQuery.of(context).size.width *
                      percent.clamp(0.0, 1.0) *
                      0.85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOver
                          ? [AppColors.pinkRed, AppColors.deepRose]
                          : [AppColors.purple, AppColors.pinkRed],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Spent / Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Spent", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                  Text(
                    "₹${spent.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isOver ? "Over by" : "Remaining",
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                  Text(
                    "₹${remaining.abs().toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isOver ? AppColors.pinkRed : AppColors.cyanLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
