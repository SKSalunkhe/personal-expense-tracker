import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('expenses').add({
      'userId': user.uid,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getExpenses() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }

  Future<void> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    await _firestore.collection('expenses').doc(id).update({
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
    });
  }
}