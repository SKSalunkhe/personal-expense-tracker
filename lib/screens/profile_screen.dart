import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../widgets/expense_chart.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/weekly_line_chart.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logoutUser(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.logoutUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ExpenseService expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: expenseService.getExpenses(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final expenses = snapshot.data!.docs;

          // Map<String, double> categoryTotals = {};
          // Map<String, double> monthlyTotals = {};
          // Map<String, double> weeklyTotals = {};
          //
          // for (var expense in expenses) {
          //   final category = expense['category'];
          //   final amount = (expense['amount'] as num).toDouble();
          //   final date = (expense['date'] as Timestamp).toDate();
          //
          //   // Category totals
          //   categoryTotals[category] =
          //       (categoryTotals[category] ?? 0) + amount;

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// PROFILE SECTION
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Email: ${user?.email ?? 'No email'}",
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 10),

                Text(
                  "User ID: ${user?.uid ?? 'No user id'}",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => logoutUser(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                  ),
                ),

                const SizedBox(height: 40),

                /// ANALYTICS TITLE
                const Text(
                  "Spending Analytics",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// CATEGORY PIE CHART
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Category Wise Spending",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ExpenseChart(categoryData: categoryTotals),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// MONTHLY BAR CHART
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Monthly Spending",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        MonthlyBarChart(monthlyData: monthlyTotals),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// WEEKLY TREND CHART
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Weekly Spending Trend",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        WeeklyLineChart(weeklyData: weeklyTotals),
                      ],
                    ),
                  ),
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