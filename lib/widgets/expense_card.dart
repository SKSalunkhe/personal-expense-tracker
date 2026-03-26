import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant_outlined;
      case 'Transport': return Icons.directions_car_outlined;
      case 'Shopping': return Icons.shopping_bag_outlined;
      case 'Bills': return Icons.receipt_long_outlined;
      case 'Entertainment': return Icons.movie_outlined;
      case 'Health': return Icons.favorite_border;
      default: return Icons.payments_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return AppColors.orange;
      case 'Transport': return AppColors.cyan;
      case 'Shopping': return AppColors.purpleLight;
      case 'Bills': return AppColors.pinkRed;
      case 'Entertainment': return const Color(0xFFFFD166);
      case 'Health': return const Color(0xFF06D6A0);
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: Text(
          "₹${amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.pinkRed,
          ),
        ),
      ),
    );
  }
}