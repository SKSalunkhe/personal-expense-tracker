import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      await authService.loginUser(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),            ),

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
              child: const Text("Don't have an account? Signup"),
            ),
          ],
        ),
      ),
    );
  }
}