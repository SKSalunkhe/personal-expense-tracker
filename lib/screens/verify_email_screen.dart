import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto-check every 4 seconds if user verified their email
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Checks Firebase if email is verified yet
  Future<void> _checkVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _timer?.cancel();
        // ✅ Auto-navigate to home once verified
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // silently ignore reload errors
    }
  }

  // Resend verification email with 30s cooldown
  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      setState(() {
        _canResend = false;
        _resendCooldown = 30;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );

      // Countdown timer so user knows when they can resend again
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            t.cancel();
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send email. Try again later.')),
      );
    }
  }

  Future<void> _logout() async {
    _timer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        automaticallyImplyLeading: false, // removes back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 90,
              color: AppColors.teal,
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Check Your Inbox!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 12),

            // Email display
            Text(
              'A verification link was sent to:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              email,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The app will open automatically once you verify.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),

            // Resend button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canResend ? _resendEmail : null,
                icon: const Icon(Icons.email_outlined),
                label: Text(
                  _canResend
                      ? 'Resend Verification Email'
                      : 'Resend in $_resendCooldown seconds...',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Back to login
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}