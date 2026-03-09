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
import '../constants/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilter = 'All';

  bool budgetWarningShown = false;
  bool budgetExceededShown = false;

  final TextEditingController searchController = TextEditingController();

  final List<String> filterCategories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
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
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () => logoutUser(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by title",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(
                labelText: "Filter by Category",
                border: OutlineInputBorder(),
              ),
              items: filterCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allExpenses = snapshot.data!.docs;

                final categoryFiltered = selectedFilter == 'All'
                    ? allExpenses
                    : allExpenses.where((expense) {
                  return expense['category'] == selectedFilter;
                }).toList();

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

                  if (expenseDate.month == now.month &&
                      expenseDate.year == now.year) {
                    monthlyAmount += amount;
                  }
                }

                Map<String, double> categoryTotals = {};

                for (var expense in expenses) {
                  final category = expense['category'];
                  final amount = (expense['amount'] as num).toDouble();

                  categoryTotals[category] =
                      (categoryTotals[category] ?? 0) + amount;
                }

                Map<String, double> monthlyTotals = {
                  'Jan': 0,
                  'Feb': 0,
                  'Mar': 0,
                  'Apr': 0,
                  'May': 0,
                  'Jun': 0,
                  'Jul': 0,
                  'Aug': 0,
                  'Sep': 0,
                  'Oct': 0,
                  'Nov': 0,
                  'Dec': 0,
                };

                Map<String, double> weeklyTotals = {
                  'Mon': 0,
                  'Tue': 0,
                  'Wed': 0,
                  'Thu': 0,
                  'Fri': 0,
                  'Sat': 0,
                  'Sun': 0,
                };

                const monthNames = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];

                const weekNames = [
                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                ];

                for (var expense in expenses) {
                  final amount = (expense['amount'] as num).toDouble();
                  final date = (expense['date'] as Timestamp).toDate();

                  final monthName = monthNames[date.month - 1];
                  monthlyTotals[monthName] = (monthlyTotals[monthName] ?? 0) + amount;

                  final weekIndex = date.weekday - 1;
                  final weekName = weekNames[weekIndex];
                  weeklyTotals[weekName] = (weeklyTotals[weekName] ?? 0) + amount;
                }

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text("No expenses found"),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: budgetService.getBudget(),
                      builder: (context, budgetSnapshot) {
                        double monthlyBudget = 0;

                        if (budgetSnapshot.hasData && budgetSnapshot.data!.exists) {
                          monthlyBudget =
                              (budgetSnapshot.data!['monthlyBudget'] as num).toDouble();
                        }

                        double remainingBudget = monthlyBudget - monthlyAmount;

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
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.teal,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Expenses",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "This Month",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "₹${monthlyAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Monthly Budget",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "₹${monthlyBudget.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Remaining Budget",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "₹${remainingBudget.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: remainingBudget < 0 ? Colors.redAccent : Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            exportService.exportExpenses(allExpenses);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Export CSV"),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                "Category Wise Spending",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ExpenseChart(categoryData: categoryTotals),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                "Monthly Spending Bar Graph",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              MonthlyBarChart(monthlyData: monthlyTotals),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                "Weekly Spending Trend",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              WeeklyLineChart(weeklyData: weeklyTotals),
                            ],
                          ),
                        ),
                      ),
                    ),

                    ...expenses.map((expense) {
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color:  AppColors.deepRose,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}