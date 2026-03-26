import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_chart.dart';
import 'add_expense_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/budget_service.dart';
import 'budget_screen.dart';
import '../services/export_service.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/weekly_line_chart.dart';
import '../constants/colors.dart';
import 'package:table_calendar/table_calendar.dart';
import '../screens/calendar_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String selectedFilter = 'All';
  bool budgetWarningShown = false;
  bool budgetExceededShown = false;
  DateTime? lastNotificationTime;

  bool canShowNotification() {
    if (lastNotificationTime == null) {
      lastNotificationTime = DateTime.now();
      return true;
    }
    final difference = DateTime.now().difference(lastNotificationTime!);
    if (difference.inMinutes >= 1) {
      lastNotificationTime = DateTime.now();
      return true;
    }
    return false;
  }

  double calculateRemaining(double budget, double spent) => budget - spent;

  final TextEditingController searchController = TextEditingController();

  final List<String> filterCategories = [
    'All', 'Food', 'Transport', 'Shopping',
    'Bills', 'Entertainment', 'Health', 'Other',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void goToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
  }

  Future<void> logoutUser(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.logoutUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseService expenseService = ExpenseService();
    final BudgetService budgetService = BudgetService();
    final ExportService exportService = ExportService();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          "Transactions",
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.textMuted),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline, color: AppColors.textMuted),
          ),
          IconButton(
            onPressed: () => logoutUser(context),
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: "Search by title...",
                hintStyle: const TextStyle(color: AppColors.textDimmed),
                prefixIcon: const Icon(Icons.search, color: AppColors.textDimmed, size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textDimmed, size: 18),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // ── Category Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              dropdownColor: AppColors.darkCard,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                labelText: "Filter by Category",
                labelStyle: const TextStyle(color: AppColors.textDimmed, fontSize: 13),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              items: filterCategories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedFilter = value!);
              },
            ),
          ),
          const SizedBox(height: 4),

          // ── Expense List ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                final allExpenses = snapshot.data!.docs;

                double totalSpent = 0;
                for (var e in allExpenses) {
                  totalSpent += (e['amount'] as num).toDouble();
                }

                final categoryFiltered = selectedFilter == 'All'
                    ? allExpenses
                    : allExpenses.where((e) => e['category'] == selectedFilter).toList();

                final query = searchController.text.toLowerCase().trim();
                final expenses = categoryFiltered.where((expense) {
                  final title = expense['title'].toString().toLowerCase();
                  return title.contains(query);
                }).toList();

                double totalAmount = 0;
                double monthlyAmount = 0;
                final now = DateTime.now();

                for (var expense in expenses) {
                  final amount = (expense['amount'] as num).toDouble();
                  final expenseDate = (expense['date'] as Timestamp).toDate();
                  totalAmount += amount;
                  if (expenseDate.month == now.month && expenseDate.year == now.year) {
                    monthlyAmount += amount;
                  }
                }

                if (expenses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, color: AppColors.textDimmed, size: 48),
                        SizedBox(height: 12),
                        Text("No expenses found", style: TextStyle(color: AppColors.textGrey)),
                      ],
                    ),
                  );
                }

                double monthlyBudget = 0;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // ── Summary Card ──
                    StreamBuilder<DocumentSnapshot>(
                      stream: budgetService.getBudget(),
                      builder: (context, budgetSnapshot) {
                        if (budgetSnapshot.hasData && budgetSnapshot.data!.exists) {
                          monthlyBudget =
                              (budgetSnapshot.data!['monthlyBudget'] as num).toDouble();
                        }

                        double remainingBudget = monthlyBudget - monthlyAmount;
                        final totalDays = DateTime(now.year, now.month + 1, 0).day;
                        final daysPassed = now.day;
                        final daysRemaining = totalDays - daysPassed;

                        if (monthlyBudget > 0 && daysRemaining > 0) {
                          final message =
                              "You spent ₹${monthlyAmount.toStringAsFixed(0)} in $daysPassed days.\n"
                              "₹${remainingBudget.toStringAsFixed(0)} remaining for $daysRemaining days.";
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (canShowNotification()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          });
                        }

                        if (monthlyBudget > 0) {
                          final usedPercent = monthlyAmount / monthlyBudget;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (usedPercent >= 1 && !budgetExceededShown) {
                              budgetExceededShown = true;
                              budgetWarningShown = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Budget exceeded! Please control your expenses."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else if (usedPercent >= 0.8 && !budgetWarningShown) {
                              budgetWarningShown = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Warning: You have used 80% of your monthly budget."),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          });
                        }

                        if (monthlyBudget > 0 && monthlyAmount < monthlyBudget * 0.8) {
                          budgetWarningShown = false;
                          budgetExceededShown = false;
                        }

                        return Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.expenseGradient,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.purple.withOpacity(0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SummaryItem(label: "Total Spent", value: "₹${totalAmount.toStringAsFixed(0)}"),
                                  _SummaryItem(label: "This Month", value: "₹${monthlyAmount.toStringAsFixed(0)}"),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(height: 1, color: AppColors.darkBorder),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SummaryItem(label: "Budget", value: "₹${monthlyBudget.toStringAsFixed(0)}"),
                                  _SummaryItem(
                                    label: "Remaining",
                                    value: "₹${remainingBudget.toStringAsFixed(0)}",
                                    valueColor: remainingBudget < 0 ? AppColors.pinkRed : AppColors.cyanLight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // ── Export Button ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.roseGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pinkRed.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await exportService.exportExpensesToPDF(allExpenses, monthlyBudget);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("PDF exported successfully")),
                              );
                            },
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("Export PDF", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),

                    // ── Transactions Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          Icon(Icons.history, color: AppColors.textGrey, size: 20),
                        ],
                      ),
                    ),

                    ...expenses.map((expense) {
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: AppColors.roseGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await expenseService.deleteExpense(expense.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Expense deleted")),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddExpenseScreen(
                                  expenseId: expense.id,
                                  initialTitle: expense['title'],
                                  initialAmount: (expense['amount'] as num).toDouble(),
                                  initialCategory: expense['category'],
                                  initialDate: (expense['date'] as Timestamp).toDate(),
                                ),
                              ),
                            );
                          },
                          child: ExpenseCard(
                            title: expense['title'],
                            amount: (expense['amount'] as num).toDouble(),
                            category: expense['category'],
                            date: (expense['date'] as Timestamp).toDate(),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToAddExpense(context),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}