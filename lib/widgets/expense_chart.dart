import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const ExpenseChart({
    super.key,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text("No chart data available"),
      );
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    int colorIndex = 0;

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: categoryData.entries.map((entry) {
            final section = PieChartSectionData(
              value: entry.value,
              title: entry.key,
              radius: 80,
              color: colors[colorIndex++ % colors.length],
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
            return section;
          }).toList(),
        ),
      ),
    );
  }
}