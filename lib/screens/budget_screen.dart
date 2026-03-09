import 'package:flutter/material.dart';
import '../services/budget_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController budgetController = TextEditingController();
  final BudgetService budgetService = BudgetService();

  Future<void> saveBudget() async {
    final budget = double.tryParse(budgetController.text.trim());

    if (budget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid budget")),
      );
      return;
    }

    try {
      await budgetService.saveBudget(budget);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget saved successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Monthly Budget"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              controller: budgetController,
              hintText: "Enter Monthly Budget",
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Save Budget",
              onPressed: saveBudget,
            ),
          ],
        ),
      ),
    );
  }
}