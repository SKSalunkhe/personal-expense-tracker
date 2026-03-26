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

  Future<void> pickDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              surface: AppColors.darkCard,
              onSurface: AppColors.textWhite,
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

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your gender")),
      );
      return;
    }

    if (selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your date of birth")),
      );
      return;
    }

    if (!AuthService.emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email (e.g. john@gmail.com)")),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: const Text(
          "Create Account",
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                "Join Us Today",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Fill in your details to get started",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 28),

            // Name
            _buildLabel("Full Name"),
            CustomTextField(
              controller: nameController,
              hintText: "Your full name",
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 18),

            // Email
            _buildLabel("Email Address"),
            CustomTextField(
              controller: emailController,
              hintText: "you@example.com",
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 18),

            // Password
            _buildLabel("Password"),
            CustomTextField(
              controller: passwordController,
              hintText: "Min. 6 characters",
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 18),

            // Gender
            _buildLabel("Gender"),
            DropdownButtonFormField<String>(
              value: selectedGender,
              dropdownColor: AppColors.darkCard,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: "Select Gender",
                hintStyle: const TextStyle(color: AppColors.textDimmed),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.wc_outlined, color: AppColors.textDimmed, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              items: genderOptions.map((g) {
                return DropdownMenuItem(value: g, child: Text(g));
              }).toList(),
              onChanged: (val) => setState(() => selectedGender = val),
            ),
            const SizedBox(height: 18),

            // DOB
            _buildLabel("Date of Birth"),
            GestureDetector(
              onTap: pickDob,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.textDimmed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedDob == null
                              ? "Select date of birth"
                              : "${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}",
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedDob == null ? AppColors.textDimmed : AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textDimmed, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Button
            CustomButton(text: "Create Account", onPressed: signupUser),
            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Sign In",
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}