import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../constants/colors.dart';

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
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    amountController = TextEditingController(
        text: widget.initialAmount?.toString() ?? '');
    selectedCategory = widget.initialCategory ?? 'Food';
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
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
      setState(() => selectedDate = picked);
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
    final isEdit = widget.expenseId != null;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: Text(
          isEdit ? "Edit Expense" : "Add Expense",
          style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header gradient card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? "Update Expense" : "New Expense",
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Fill in the details below",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text("Title", style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: titleController,
              hintText: "e.g. Lunch, Taxi, Groceries",
              prefixIcon: Icons.label_outline,
            ),
            const SizedBox(height: 18),

            // Amount
            const Text("Amount (₹)", style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: amountController,
              hintText: "0.00",
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: 18),

            // Category
            const Text("Category", style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              dropdownColor: AppColors.darkCard,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkInput,
                hintStyle: const TextStyle(color: AppColors.textDimmed),
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
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textDimmed, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value!);
              },
            ),
            const SizedBox(height: 18),

            // Date
            const Text("Date", style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickDate,
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
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(fontSize: 15, color: AppColors.textWhite),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textDimmed, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: isEdit ? "Update Expense" : "Save Expense",
              onPressed: saveExpense,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}