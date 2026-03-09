import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../constants/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  Future<void> signupUser() async {

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    try {
      await authService.signUpUser(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Signup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create Account",
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
              text: "Signup",
              onPressed: signupUser,
            ),
          ],
        ),
      ),
    );
  }
}