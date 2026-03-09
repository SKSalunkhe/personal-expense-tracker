import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? expenseId;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  final DateTime? initialDate;

  const AddExpenseScreen({
    super.key,
    this.expenseId,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialDate,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;

  final ExpenseService expenseService = ExpenseService();

  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.initialTitle ?? '',
    );

    amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );

    selectedCategory = widget.initialCategory ?? 'Food';
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveExpense() async {
    if (titleController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    try {
      if (widget.expenseId == null) {
        await expenseService.addExpense(
          title: titleController.text.trim(),
          amount: amount,
          category: selectedCategory,
          date: selectedDate,
        );
      } else {
        await expenseService.updateExpense(
          id: widget.expenseId!,
          title: titleController.text.trim(),
          amount: amount,
          category: selectedCategory,
          date: selectedDate,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.expenseId == null
                ? "Expense saved successfully"
                : "Expense updated successfully",
          ),
        ),
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
        title: Text(widget.expenseId == null ? "Add Expense" : "Edit Expense"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              controller: titleController,
              hintText: "Expense Title",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: amountController,
              hintText: "Amount",
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Category",
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey),
              ),
              title: Text(
                "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: widget.expenseId == null ? "Save Expense" : "Update Expense",
              onPressed: saveExpense,
            ),
          ],
        ),
      ),
    );
  }
}