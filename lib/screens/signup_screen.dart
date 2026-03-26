import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'verify_email_screen.dart';
import '../constants/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final AuthService authService = AuthService();

  String? selectedGender;
  DateTime? selectedDob;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  // DOB picker
  Future<void> pickDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDob = picked);
    }
  }

  Future<void> signupUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    // Check 1: empty fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Check 2: gender selected
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your gender")),
      );
      return;
    }

    // Check 3: DOB selected
    if (selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your date of birth")),
      );
      return;
    }

    // Check 4: strong regex
    if (!AuthService.emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email (e.g. john@gmail.com)")),
      );
      return;
    }

    // Check 5: password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    try {
      await authService.signUpUser(
        email: email,
        password: password,
        name: name,
        gender: selectedGender!,
        dob: selectedDob!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent! Please check your inbox.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else {
        message = e.message ?? 'Signup failed.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Fill in your details to get started",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),

            // Name
            CustomTextField(
              controller: nameController,
              hintText: "Full Name",
            ),
            const SizedBox(height: 16),

            // Email
            CustomTextField(
              controller: emailController,
              hintText: "Email Address",
            ),
            const SizedBox(height: 16),

            // Password
            CustomTextField(
              controller: passwordController,
              hintText: "Password (min 6 characters)",
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Gender dropdown
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: InputDecoration(
                hintText: "Select Gender",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.beige),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.beige),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.teal, width: 2),
                ),
              ),
              items: genderOptions.map((g) {
                return DropdownMenuItem(value: g, child: Text(g));
              }).toList(),
              onChanged: (val) => setState(() => selectedGender = val),
            ),
            const SizedBox(height: 16),

            // DOB picker
            GestureDetector(
              onTap: pickDob,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.beige),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDob == null
                          ? "Date of Birth"
                          : "${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}",
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDob == null ? Colors.grey[500] : AppColors.textDark,
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, color: AppColors.teal, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Signup button
            CustomButton(
              text: "Create Account",
              onPressed: signupUser,
            ),
            const SizedBox(height: 12),

            // Back to login
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: AppColors.teal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}