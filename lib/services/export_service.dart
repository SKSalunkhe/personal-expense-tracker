import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class ExportService {
  Future<void> exportExpenses(List<QueryDocumentSnapshot> expenses) async {
    final buffer = StringBuffer();

    buffer.writeln("Title,Amount,Category,Date");

    for (var expense in expenses) {
      final data = expense.data() as Map<String, dynamic>;

      final title = "${data['title']}".replaceAll(',', ' ');
      final amount = data['amount'];
      final category = "${data['category']}".replaceAll(',', ' ');
      final date = (data['date'] as Timestamp).toDate().toString();

      buffer.writeln("$title,$amount,$category,$date");
    }

    final bytes = buffer.toString().codeUnits;
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "expenses.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}