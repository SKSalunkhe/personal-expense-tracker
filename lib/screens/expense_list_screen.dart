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

  double calculateRemaining(double budget, double spent) {
    return budget - spent;
  }

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
        title: const Text(
          "Transactions...",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(),
                ),
              );
            },
          ),
          /*IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
          ),*/
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

                double totalSpent = 0;

                for (var e in allExpenses) {
                  totalSpent += (e['amount'] as num).toDouble();
                }


                final categoryFiltered = selectedFilter == 'All'
                    ? allExpenses
                    : allExpenses.where((expense) {
                  return expense['category'] == selectedFilter;
                }).toList();

                final query = searchController.text.toLowerCase().trim();

                final expenses = categoryFiltered.where((expense) {
                  final title = expense['title'].toString().toLowerCase();
                  final expenseDate = (expense['date'] as Timestamp).toDate();

                  bool matchesSearch = title.contains(query);

                  return matchesSearch ;
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

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text("No expenses found"),
                  );
                }

                double monthlyBudget = 0;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: budgetService.getBudget(),
                      builder: (context, budgetSnapshot) {

                        if (budgetSnapshot.hasData && budgetSnapshot.data!.exists) {
                          monthlyBudget =
                              (budgetSnapshot.data!['monthlyBudget'] as num).toDouble();
                        }

                        double remainingBudget = monthlyBudget - monthlyAmount;
                        final now = DateTime.now();

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
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1F7A78),
                                Color(0xFF2C9C99),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () async {
                            await exportService.exportExpensesToPDF(
                              allExpenses,
                              monthlyBudget,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("PDF exported successfully"),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Export PDF"),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.history),
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
                          color: AppColors.deepRose,
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