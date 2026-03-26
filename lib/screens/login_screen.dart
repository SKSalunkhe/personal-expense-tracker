import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'verify_email_screen.dart';
import '../constants/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  Future<void> loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Check 1: empty fields
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Check 2: strong regex validation
    if (!AuthService.emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email (e.g. john@gmail.com)")),
      );
      return;
    }

    try {
      User? user = await authService.loginUser(email, password);

      // Check 3: is email verified?
      if (user != null && !user.emailVerified) {
        // Not verified — sign them out & send to verify screen
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please verify your email first. Check your inbox."),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
          );
        }
        return;
      }

      // ✅ Verified — go to dashboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Try again.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      } else {
        message = e.message ?? 'Login failed.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Personal Expense Tracker",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 30),
            CustomTextField(
              controller: emailController,
              hintText: "Enter Email",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              hintText: "Enter Password",
              obscureText: true,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Login",
              onPressed: loginUser,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: goToSignup,
              child: const Text(
                "Don't have an account? Signup",
                style: TextStyle(color: AppColors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}