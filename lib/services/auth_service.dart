import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Strong regex — reusable across all screens
  static final RegExp emailRegex =
  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  Future<User?> signUpUser({
    required String email,
    required String password,
    required String name,
    required String gender,
    required DateTime dob,
  }) async {
    try {
      // Step 1: Create user in Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Step 2: Update display name in Firebase Auth
      await user?.updateDisplayName(name);

      // Step 3: Save all user data to Firestore under their email
      await _firestore.collection('users').doc(email).set({
        'uid': user?.uid,
        'name': name,
        'email': email,
        'gender': gender,
        'dob': "${dob.day}/${dob.month}/${dob.year}",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Step 4: Send verification email
      await user?.sendEmailVerification();

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload to get latest emailVerified status
      await userCredential.user?.reload();
      return _auth.currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // ✅ Fetch user data from Firestore by email
  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
