import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../screens/profile_screen.dart';
import '../screens/add_expense_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/budget_screen.dart';
import '../constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String userName = '';
  String userGender = '';
  bool isLoading = true;

  final List<Map<String, dynamic>> expenseTips = [
    {
      'icon': Icons.coffee_outlined,
      'tip': 'Skip one coffee a day',
      'saving': 'Save ₹1,500/month',
      'color': AppColors.orange,
    },
    {
      'icon': Icons.fastfood_outlined,
      'tip': 'Cook at home 3x a week',
      'saving': 'Save ₹3,000/month',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.directions_bus_outlined,
      'tip': 'Use public transport',
      'saving': 'Save ₹2,000/month',
      'color': AppColors.pinkRed,
    },
    {
      'icon': Icons.subscriptions_outlined,
      'tip': 'Audit unused subscriptions',
      'saving': 'Save ₹500/month',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'tip': 'Wait 24hrs before buying',
      'saving': 'Avoid impulse spending',
      'color': AppColors.orange,
    },
    {
      'icon': Icons.savings_outlined,
      'tip': 'Save 20% of income first',
      'saving': 'Build emergency fund',
      'color': AppColors.purpleLight,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
    _checkRollover();
  }

  Future<void> loadUserData() async {
    try {
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
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkRollover() async {
    try {
      final now = DateTime.now();
      if (now.day != 1) return;

      final expenseService = ExpenseService();
      final expenses = await expenseService.getExpenses().first;
      final lastMonth = DateTime(now.year, now.month - 1);
      double lastMonthSpent = 0;

      for (var doc in expenses.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        if (date.month == lastMonth.month && date.year == lastMonth.year) {
          lastMonthSpent += (doc['amount'] as num).toDouble();
        }
      }

      final budgetService = BudgetService();
      final rolledOver = await budgetService.checkAndRollover(lastMonthSpent);

      if (rolledOver != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 ₹$rolledOver saved from last month added to this month's budget!"),
            backgroundColor: AppColors.purple,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // silently ignore
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String getEmoji() {
    if (userGender == 'Male') return '👨';
    if (userGender == 'Female') return '👩';
    return '👤';
  }

  Future<void> logout() async {
    await _authService.logoutUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: const Text(
                'TrackMint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Expense tracker',
              style: TextStyle(
                color: AppColors.textDimmed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.textMuted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Greeting Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.purple.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.2),
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
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${getGreeting()} ${getEmoji()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName.isNotEmpty ? userName : 'Welcome!',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track your expenses & save smarter 💰',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ──
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Add Expense',
                  color: AppColors.pinkRed,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddExpenseScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _QuickActionCard(
                  icon: Icons.list_alt_outlined,
                  label: 'Transactions',
                  color: AppColors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _QuickActionCard(
                  icon: Icons.bar_chart_outlined,
                  label: 'Budget',
                  color: AppColors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BudgetScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Tips ──
            const Text(
              '💡 Tips to Save More',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenseTips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tip = expenseTips[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (tip['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tip['icon'] as IconData,
                          color: tip['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['tip'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tip['saving'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Card ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}