import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveBudget(double budget) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('budgets').doc(user.uid).set({
      'userId': user.uid,
      'monthlyBudget': budget,
      'savings': 0
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getBudget() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return _firestore.collection('budgets').doc(user.uid).snapshots();
  }

  Future<void> updateSavings(double savings) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('budgets').doc(user.uid).update({
      'savings': savings
    });
  }
}