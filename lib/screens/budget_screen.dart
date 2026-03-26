import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/budget_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../constants/colors.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController budgetController = TextEditingController();
  final BudgetService budgetService = BudgetService();

  Future<void> saveBudget() async {
    final budget = double.tryParse(budgetController.text.trim());

    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid budget amount")),
      );
      return;
    }

    try {
      await budgetService.saveBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget saved successfully!")),
        );
        budgetController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: const Text(
          "Monthly Budget",
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current Budget Card ──
            StreamBuilder<DocumentSnapshot>(
              stream: budgetService.getBudget(),
              builder: (context, snapshot) {
                double baseBudget = 0;
                double rollover = 0;
                double totalBudget = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  baseBudget = (data['monthlyBudget'] as num?)?.toDouble() ?? 0;
                  rollover = (data['rolloverAmount'] as num?)?.toDouble() ?? 0;
                  totalBudget = baseBudget + rollover;
                }

                return Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "This Month's Budget",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "₹${totalBudget.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _BudgetInfoTile(
                              label: "Base Budget",
                              value: "₹${baseBudget.toStringAsFixed(2)}",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BudgetInfoTile(
                              label: "Rolled Over",
                              value: "₹${rollover.toStringAsFixed(2)}",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Set New Budget ──
            const Text(
              "Set Base Budget",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Update your monthly spending limit",
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: budgetController,
              hintText: "Enter Monthly Budget (₹)",
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: 16),
            CustomButton(text: "Save Budget", onPressed: saveBudget),
            const SizedBox(height: 36),

            // ── Rollover History ──
            Row(
              children: const [
                Icon(Icons.savings_outlined, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  "Savings Rollover History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: budgetService.getRolloverHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_outlined, color: AppColors.textDimmed, size: 36),
                        SizedBox(height: 10),
                        Text(
                          "No rollover history yet.\nSave money this month to see it here! 🎯",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final history = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final record = history[index].data() as Map<String, dynamic>;
                    final month = record['month'] ?? '';
                    final saved = (record['savedAmount'] as num?)?.toDouble() ?? 0;
                    final addedTo = record['addedToMonth'] ?? '';

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
                              gradient: AppColors.greenGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.savings_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Saved in $month",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Added to $addedTo budget",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.greenGradient.createShader(bounds),
                            child: Text(
                              "+₹${saved.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BudgetInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}