import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // ── Save base monthly budget ──
  Future<void> saveBudget(double budget) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _firestore.collection('budgets').doc(_userId).set({
      'userId': _userId,
      'monthlyBudget': budget,
    }, SetOptions(merge: true));
  }

  // ── Get budget stream ──
  Stream<DocumentSnapshot> getBudget() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection('budgets').doc(_userId).snapshots();
  }

  // ── Update savings ──
  Future<void> updateSavings(double savings) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    await _firestore.collection('budgets').doc(_userId).update({
      'savings': savings,
    });
  }

  // ── Check & perform rollover if needed ──
  Future<String?> checkAndRollover(double lastMonthSpent) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final thisMonthKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Get last month
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthKey =
        "${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}";

    final budgetDoc =
    await _firestore.collection('budgets').doc(_userId).get();

    if (!budgetDoc.exists) return null;

    final data = budgetDoc.data() as Map<String, dynamic>;
    final lastRolloverMonth = data['lastRolloverMonth'] ?? '';

    // Already rolled over this month — skip
    if (lastRolloverMonth == thisMonthKey) return null;

    final double baseBudget = (data['monthlyBudget'] as num).toDouble();
    final double prevRollover = (data['rolloverAmount'] as num?)?.toDouble() ?? 0;

    // Calculate leftover (Base + Previous Rollover - Last Month Spending)
    final double leftover = (baseBudget + prevRollover) - lastMonthSpent;

    if (leftover <= 0) {
      // Nothing to rollover — just mark as done
      await _firestore.collection('budgets').doc(_userId).update({
        'lastRolloverMonth': thisMonthKey,
        'rolloverAmount': 0,
      });
      return null;
    }

    // Add leftover to rollover amount
    await _firestore.collection('budgets').doc(_userId).update({
      'rolloverAmount': leftover,
      'lastRolloverMonth': thisMonthKey,
    });

    // Save to rollover history
    await _firestore
        .collection('budgets')
        .doc(_userId)
        .collection('rollover_history')
        .doc(lastMonthKey)
        .set({
      'month': lastMonthKey,
      'savedAmount': leftover,
      'addedToMonth': thisMonthKey,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return leftover.toStringAsFixed(2);
  }

  // ── Get rollover history ──
  Stream<QuerySnapshot> getRolloverHistory() {
    return _firestore
        .collection('budgets')
        .doc(_userId)
        .collection('rollover_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}