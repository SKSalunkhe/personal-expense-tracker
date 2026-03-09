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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.beige,
          child: Icon(
            Icons.payments_outlined,
            color: AppColors.teal,
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category),
            Text(DateFormat('dd MMM yyyy').format(date)),
          ],
        ),
        trailing: Text(
          "₹${amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepRose,
          ),
        ),
      ),
    );
  }
}