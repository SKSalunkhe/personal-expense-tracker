import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/expense.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expense Tracker',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [
    Expense(
      title: 'Food',
      amount: 120,
      date: DateTime.now(),
      category: Category.food,
    ),
    Expense(
      title: 'Travel',
      amount: 60,
      date: DateTime.now(),
      category: Category.travel,
    ),
    Expense(
      title: 'Shopping',
      amount: 300,
      date: DateTime.now(),
      category: Category.shopping,
    ),
  ];

  double get _total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  void _openAddExpenseSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    DateTime? selectedDate;
    Category selectedCategory = Category.food;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // Use StatefulBuilder so dropdown/date updates inside bottom sheet UI
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),

                // Category dropdown
                Row(
                  children: [
                    const Text('Category: '),
                    const SizedBox(width: 10),
                    DropdownButton<Category>(
                      value: selectedCategory,
                      items: Category.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedCategory = value);
                      },
                    ),
                  ],
                ),

                // Date picker
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'No date selected'
                            : DateFormat.yMMMd().format(selectedDate!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: now,
                        );
                        if (picked == null) return;
                        setModalState(() => selectedDate = picked);
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),



                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text);

                    if (title.isEmpty || amount == null || amount <= 0) return;

                    setState(() {
                      _expenses.add(
                        Expense(
                          title: title,
                          amount: amount,
                          date: selectedDate ?? DateTime.now(),
                          category: selectedCategory,
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  IconData _iconForCategory(Category c) {
    switch (c) {
      case Category.food:
        return Icons.restaurant;
      case Category.travel:
        return Icons.directions_car;
      case Category.shopping:
        return Icons.shopping_bag;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Expense Tracker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total: ₹${_total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('No expenses yet. Tap + to add.'))
                : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final e = _expenses[index];
                return Dismissible(
                  key: ValueKey('${e.title}-${e.amount}-${e.date}-$index'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() => _expenses.removeAt(index));
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(e.date)} • ${e.category.name.toUpperCase()}',
                    ),
                    trailing: Text('₹${e.amount.toStringAsFixed(0)}'),
                    leading: Icon(_iconForCategory(e.category)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}