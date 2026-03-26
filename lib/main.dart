import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/signup_screen.dart';
import 'constants/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple,
          secondary: AppColors.cyan,
          surface: AppColors.darkCard,
          background: AppColors.darkBg,
          onBackground: AppColors.textWhite,
          onSurface: AppColors.textWhite,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.darkBg,
          foregroundColor: AppColors.textWhite,
          titleTextStyle: TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColors.textMuted),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkInput,
          hintStyle: const TextStyle(color: AppColors.textDimmed),
          labelStyle: const TextStyle(color: AppColors.textDimmed),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textWhite),
          bodyMedium: TextStyle(color: AppColors.textMuted),
          bodySmall: TextStyle(color: AppColors.textGrey),
          titleLarge: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w500),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkBorder),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkCard,
          contentTextStyle: const TextStyle(color: AppColors.textWhite),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.purple,
        ),
      ),

      // ✅ Named routes — all screens registered here
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/home': (context) => const DashboardScreen(),
      },

      // ✅ StreamBuilder — protects all screens
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Waiting for Firebase to respond
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is logged in
          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;

            // ✅ Verified — go to dashboard
            if (user.emailVerified) {
              return const DashboardScreen();
            }

            // ❌ Not verified — go to verify screen
            return const VerifyEmailScreen();
          }

          // Not logged in — go to login
          return const LoginScreen();
        },
      ),
    );
  }
}
/*

## 🎉 Everything is Now Complete!

Here's the full flow your app now has:
```
Open App
│
▼
StreamBuilder checks auth state
│
├── Not logged in         →  LoginScreen
│       │
│       ├── Regex check
│       ├── Firebase login
│       ├── Email verified?  No → VerifyEmailScreen
│       └── Yes             →  DashboardScreen ✅
│
├── Logged in, unverified  →  VerifyEmailScreen
│       │                      (auto-checks every 4s)
│       └── Verified       →  DashboardScreen ✅
│
└── Logged in & verified   →  DashboardScreen ✅
│
├── Greeting with name from Firestore
├── Quick Actions (Add, Transactions, Budget)
└── Expense saving tips

*/
