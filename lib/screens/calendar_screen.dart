import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/expense_service.dart';
import '../constants/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDay = DateTime.now();
  Map<DateTime, List<dynamic>> events = {};
  final ExpenseService expenseService = ExpenseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textMuted,
        elevation: 0,
        title: const Text(
          "Expense Calendar",
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Calendar ──
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleTextStyle: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                headerPadding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: AppColors.textMuted),
                weekendTextStyle: const TextStyle(color: AppColors.pinkRed),
                outsideTextStyle: const TextStyle(color: AppColors.textDimmed),
                selectedDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purple, AppColors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.bold),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                markerDecoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textGrey, fontSize: 12),
                weekendStyle: TextStyle(color: AppColors.pinkRed, fontSize: 12),
              ),
              eventLoader: (day) {
                return events[DateTime(day.year, day.month, day.day)] ?? [];
              },
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() => selectedDay = selected);
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Expense List ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                final allExpenses = snapshot.data!.docs;

                events.clear();
                for (var expense in allExpenses) {
                  final date = (expense['date'] as Timestamp).toDate();
                  final day = DateTime(date.year, date.month, date.day);
                  events[day] ??= [];
                  events[day]!.add(expense);
                }

                final expenses = allExpenses.where((expense) {
                  final date = (expense['date'] as Timestamp).toDate();
                  return date.year == selectedDay.year &&
                      date.month == selectedDay.month &&
                      date.day == selectedDay.day;
                }).toList();

                if (expenses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_outlined, color: AppColors.textDimmed, size: 40),
                        SizedBox(height: 10),
                        Text(
                          "No expenses on this day",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final e = expenses[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['title'],
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  e['category'],
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "₹${e['amount']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.pinkRed,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}