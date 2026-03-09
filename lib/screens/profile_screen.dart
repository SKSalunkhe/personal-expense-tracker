import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              "Email: ${user?.email ?? 'No email'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}