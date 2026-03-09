import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyLineChart extends StatelessWidget {
  final Map<String, double> weeklyData;

  const WeeklyLineChart({
    super.key,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return const Center(child: Text("No weekly data"));
    }

    final entries = weeklyData.entries.toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              dotData: const FlDotData(show: true),
              spots: List.generate(
                entries.length,
                    (index) => FlSpot(index.toDouble(), entries[index].value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}