class Expense {
  String id;
  String title;
  double amount;
  String category;
  DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String docId) {
    return Expense(
      id: docId,
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      date: map['date'].toDate(),
    );
  }
}