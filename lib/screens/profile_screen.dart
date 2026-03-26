import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../widgets/expense_chart.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/weekly_line_chart.dart';
import 'login_screen.dart';
import '../constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String userName = '';
  String userGender = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final data = await _authService.getUserData(user.email!);
      if (data != null && mounted) {
        setState(() {
          userName = data['name'] ?? '';
          userGender = data['gender'] ?? '';
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  String getAvatarEmoji() {
    if (userGender == 'Male') return '👨';
    if (userGender == 'Female') return '👩';
    return '👤';
  }

  LinearGradient getAvatarGradient() {
    if (userGender == 'Male') return AppColors.primaryGradient;
    if (userGender == 'Female') return AppColors.roseGradient;
    return AppColors.greenGradient;
  }

  Future<void> logoutUser() async {
    await _authService.logoutUser();
    if (!mounted) return;
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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : StreamBuilder<QuerySnapshot>(
              stream: expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final expenses = snapshot.data!.docs;

                Map<String, double> categoryTotals = {};
                for (var expense in expenses) {
                  final category = expense['category'];
                  final amount = (expense['amount'] as num).toDouble();
                  categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
                }

                Map<String, double> monthlyTotals = {
                  'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0,
                  'May': 0, 'Jun': 0, 'Jul': 0, 'Aug': 0,
                  'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
                };
                Map<String, double> weeklyTotals = {
                  'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0,
                  'Fri': 0, 'Sat': 0, 'Sun': 0,
                };

                const monthNames = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                const weekNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                for (var expense in expenses) {
                  final amount = (expense['amount'] as num).toDouble();
                  final date = (expense['date'] as Timestamp).toDate();
                  monthlyTotals[monthNames[date.month - 1]] =
                      (monthlyTotals[monthNames[date.month - 1]] ?? 0) + amount;
                  weeklyTotals[weekNames[date.weekday - 1]] =
                      (weeklyTotals[weekNames[date.weekday - 1]] ?? 0) + amount;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile Card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: getAvatarGradient(),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  getAvatarEmoji(),
                                  style: const TextStyle(fontSize: 44),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userName.isNotEmpty ? userName : 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                userGender.isNotEmpty ? userGender : 'User',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  user?.email ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Logout Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.roseGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pinkRed.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: logoutUser,
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Analytics ──
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          "Spending Analytics",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pie Chart
                      _AnalyticsCard(
                        title: "Category Wise Spending",
                        child: ExpenseChart(categoryData: categoryTotals),
                      ),
                      const SizedBox(height: 16),

                      // Monthly Bar
                      _AnalyticsCard(
                        title: "Monthly Spending",
                        child: MonthlyBarChart(monthlyData: monthlyTotals),
                      ),
                      const SizedBox(height: 16),

                      // Weekly Line
                      _AnalyticsCard(
                        title: "Weekly Spending Trend",
                        child: WeeklyLineChart(weeklyData: weeklyTotals),
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AnalyticsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}