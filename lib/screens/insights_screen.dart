import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../services/budget_service.dart';
import '../constants/colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();
    final budgetService = BudgetService();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: const Text(
          "Spending Insights",
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseService.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No data yet. Start spending to see insights!",
                  style: TextStyle(color: AppColors.textGrey)),
            );
          }

          final expenses = snapshot.data!.docs;
          final now = DateTime.now();

          // ── Calculate Category Totals ──
          Map<String, double> categoryTotals = {};
          double totalSpent = 0;
          double thisMonthSpent = 0;
          double lastMonthSpent = 0;
          Map<String, double> thisMonthCat = {};
          Map<String, double> lastMonthCat = {};

          for (var e in expenses) {
            final amount = (e['amount'] as num).toDouble();
            final category = e['category'] as String;
            final date = (e['date'] as Timestamp).toDate();

            totalSpent += amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

            if (date.month == now.month && date.year == now.year) {
              thisMonthSpent += amount;
              thisMonthCat[category] = (thisMonthCat[category] ?? 0) + amount;
            }
            final lastMonth = DateTime(now.year, now.month - 1);
            if (date.month == lastMonth.month && date.year == lastMonth.year) {
              lastMonthSpent += amount;
              lastMonthCat[category] = (lastMonthCat[category] ?? 0) + amount;
            }
          }

          // ── Top Category ──
          String topCategory = '';
          double topAmount = 0;
          categoryTotals.forEach((key, value) {
            if (value > topAmount) {
              topAmount = value;
              topCategory = key;
            }
          });

          // ── Biggest Increase ──
          String biggestIncrease = '';
          double maxIncrease = 0;
          for (var cat in thisMonthCat.keys) {
            final thisVal = thisMonthCat[cat] ?? 0;
            final lastVal = lastMonthCat[cat] ?? 0;
            if (lastVal > 0) {
              final increase = ((thisVal - lastVal) / lastVal) * 100;
              if (increase > maxIncrease) {
                maxIncrease = increase;
                biggestIncrease = cat;
              }
            }
          }

          // ── Average daily spend ──
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final avgDaily = thisMonthSpent / now.day;
          final projectedSpend = avgDaily * daysInMonth;

          // ── Change vs last month ──
          double monthChange = 0;
          if (lastMonthSpent > 0) {
            monthChange = ((thisMonthSpent - lastMonthSpent) / lastMonthSpent) * 100;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero insight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Monthly Overview",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "₹${thisMonthSpent.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            monthChange >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: monthChange >= 0
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF22C55E),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${monthChange >= 0 ? '+' : ''}${monthChange.toStringAsFixed(1)}% vs last month",
                            style: TextStyle(
                              color: monthChange >= 0
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF22C55E),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Insight cards
                _InsightCard(
                  icon: Icons.category_outlined,
                  iconColor: AppColors.purple,
                  title: "Top Spending Category",
                  value: topCategory.isNotEmpty ? topCategory : "N/A",
                  subtitle: topCategory.isNotEmpty
                      ? "₹${topAmount.toStringAsFixed(0)} total"
                      : "",
                ),
                const SizedBox(height: 12),

                _InsightCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.pinkRed,
                  title: "Daily Average",
                  value: "₹${avgDaily.toStringAsFixed(0)}/day",
                  subtitle: "Projected: ₹${projectedSpend.toStringAsFixed(0)} this month",
                ),
                const SizedBox(height: 12),

                if (biggestIncrease.isNotEmpty)
                  _InsightCard(
                    icon: Icons.trending_up,
                    iconColor: AppColors.orange,
                    title: "Biggest Increase",
                    value: biggestIncrease,
                    subtitle: "+${maxIncrease.toStringAsFixed(0)}% vs last month",
                  ),
                if (biggestIncrease.isNotEmpty) const SizedBox(height: 12),

                _InsightCard(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.purpleLight,
                  title: "Total Transactions",
                  value: "${expenses.length}",
                  subtitle: "₹${totalSpent.toStringAsFixed(0)} all time",
                ),
                const SizedBox(height: 24),

                // Tips
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    "💡 Smart Tips",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (monthChange > 20)
                  _TipCard(
                    text: "Your spending is up ${monthChange.toStringAsFixed(0)}% this month. Try to cut back on $topCategory!",
                    color: AppColors.pinkRed,
                  ),

                if (avgDaily > 0)
                  _TipCard(
                    text: "At ₹${avgDaily.toStringAsFixed(0)}/day, you'll spend ₹${projectedSpend.toStringAsFixed(0)} this month.",
                    color: AppColors.purple,
                  ),

                if (topCategory.isNotEmpty)
                  _TipCard(
                    text: "$topCategory is your biggest expense. Consider setting a sub-budget for it!",
                    color: AppColors.orange,
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    )),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final Color color;

  const _TipCard({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
