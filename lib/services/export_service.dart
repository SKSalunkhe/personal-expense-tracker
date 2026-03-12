import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportService {

  Future<void> exportExpensesToPDF(
      List<QueryDocumentSnapshot> expenses,
      double monthlyBudget,
      ) async {

    final pdf = pw.Document();

    double totalSpent = 0;

    for (var e in expenses) {
      totalSpent += (e['amount'] as num).toDouble();
    }

    double savings = monthlyBudget - totalSpent;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              pw.Text(
                "Expense Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text("Monthly Budget: ₹${monthlyBudget.toStringAsFixed(2)}"),
              pw.Text("Total Spent: ₹${totalSpent.toStringAsFixed(2)}"),
              pw.Text("Savings: ₹${savings.toStringAsFixed(2)}"),

              pw.SizedBox(height: 20),

              pw.Text(
                "Transactions",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Title", "Category", "Amount", "Date"],
                data: expenses.map((e) {

                  final date = (e['date'] as Timestamp).toDate();

                  return [
                    e['title'],
                    e['category'],
                    "₹${e['amount']}",
                    "${date.day}/${date.month}/${date.year}",
                  ];

                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = Directory('/storage/emulated/0/Download');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/expense_report.pdf');

    await file.writeAsBytes(await pdf.save());

    print("PDF saved at: ${file.path}");
  }
}