import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/expense_service.dart';
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
      appBar: AppBar(title: const Text("Expense Calendar")),

      body: Column(
        children: [

          TableCalendar(
            firstDay: DateTime.utc(2023,1,1),
            lastDay: DateTime.utc(2030,12,31),
            focusedDay: selectedDay,

            eventLoader: (day) {
              return events[DateTime(day.year, day.month, day.day)] ?? [];
            },

            selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
            },

            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
              });
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: expenseService.getExpenses(),
              builder: (context, snapshot) {

                if(!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allExpenses = snapshot.data!.docs;

                events.clear();

                for (var expense in allExpenses) {

                  final date = (expense['date'] as Timestamp).toDate();
                  final day = DateTime(date.year, date.month, date.day);

                  if (events[day] == null) {
                    events[day] = [];
                  }

                  events[day]!.add(expense);
                }

                final expenses = snapshot.data!.docs.where((expense){

                  final date = (expense['date'] as Timestamp).toDate();

                  return date.year == selectedDay.year &&
                      date.month == selectedDay.month &&
                      date.day == selectedDay.day;

                }).toList();

                if(expenses.isEmpty){
                  return const Center(child: Text("No expenses today"));
                }

                return ListView(
                  children: expenses.map((e){

                    return ListTile(
                      title: Text(e['title']),
                      subtitle: Text(e['category']),
                      trailing: Text("₹${e['amount']}"),
                    );

                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}