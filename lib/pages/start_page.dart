import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:taskly_app/models/task.dart';
import 'package:taskly_app/pages/home_page.dart';

class MonthDaysPage extends StatefulWidget {
  const MonthDaysPage({super.key});

  @override
  State<MonthDaysPage> createState() => _MonthDaysPageState();
}

class _MonthDaysPageState extends State<MonthDaysPage> {
  final List<String> months = List.generate(
    12,
    (index) {
      return DateFormat('MMMM').format(DateTime(0, index + 1));
    },
  );

  int? selectedMonthIndex;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  Box? _box;

  @override
  void initState() {
    super.initState();
    _loadSelectedMonth();
    _openTaskBox();
  }

  Future<void> _openTaskBox() async {
    _box = await Hive.openBox("tasks");
    setState(() {}); // Trigger a rebuild to ensure tasks are loaded
  }

  Future<void> _loadSelectedMonth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedMonthIndex = prefs.getInt('selectedMonthIndex');
    if (savedMonthIndex != null) {
      setState(() {
        selectedMonthIndex = savedMonthIndex;
        selectedMonth = months[selectedMonthIndex!];
      });
    } else {
      setState(() {
        selectedMonthIndex =
            DateTime.now().month - 1; // Adjust for zero-based index
        selectedMonth = months[selectedMonthIndex!];
      });
    }
  }

  Future<void> _saveSelectedMonth(int monthIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedMonthIndex', monthIndex);
  }

  List<Task> _getTasksForDay(String dayKey) {
    List tasks = _box?.get(dayKey, defaultValue: []).toList() ?? [];
    return tasks.map((taskData) => Task.fromMap(taskData)).toList();
  }

  Map<String, int> _getTaskCompletionStatus(String dayKey) {
    List<Task> tasks = _getTasksForDay(dayKey);
    int completedTasks = tasks.where((task) => task.done).length;
    int totalTasks = tasks.length;
    int pendingTasks = totalTasks - completedTasks;
    return {
      "completed": completedTasks,
      "pending": pendingTasks,
      "total": totalTasks,
    };
  }

  @override
  Widget build(BuildContext context) {
    int year = DateTime.now().year;
    int daysInMonth = selectedMonthIndex != null
        ? DateTime(year, selectedMonthIndex! + 1, 0).day
        : DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Month and Day"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.red,
              ),
              child: DropdownButton<String>(
                value: selectedMonth,
                isExpanded: true,
                hint: const Text('Select a month'),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value!;
                    selectedMonthIndex = months.indexOf(selectedMonth);
                    _saveSelectedMonth(selectedMonthIndex!);
                  });
                },
                items: months.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                underline: Container(),
              ),
            ),
          ),
          if (selectedMonthIndex != null && _box != null)
            Expanded(
              child: ListView.builder(
                itemCount: daysInMonth,
                itemBuilder: (BuildContext context, int index) {
                  int dayNumber = index + 1;
                  String dayKey = "${selectedMonth}_$dayNumber";

                  DateTime date =
                      DateTime(year, selectedMonthIndex! + 1, dayNumber);
                  String formattedDate = DateFormat('dd/MM/yyyy').format(date);
                  String weekday = DateFormat('EEEE').format(date);

                  Map<String, int> taskStatus =
                      _getTaskCompletionStatus(dayKey);

                  return Card(
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day $dayNumber ($weekday)',
                            style: const TextStyle(fontSize: 17),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Completed: ${taskStatus["completed"]}/${taskStatus["total"]}, Pending: ${taskStatus["pending"]}/${taskStatus["total"]}',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              dayNumber: dayNumber,
                              monthName: selectedMonth,
                              onTaskChanged: () {
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
