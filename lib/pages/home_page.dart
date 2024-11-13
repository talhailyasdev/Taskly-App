import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskly_app/models/task.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting.

class HomePage extends StatefulWidget {
  final int dayNumber;
  final String monthName;
  final VoidCallback onTaskChanged; // Callback to notify task change
  const HomePage(
      {super.key,
      required this.dayNumber,
      required this.monthName,
      required this.onTaskChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late double _deviceheight,
      _devicewidth; //These store the dimensions of the device screen.
  Box? _box;
  // This variable represents a Hive box used for storing tasks.
  String get _dayKey =>
      "${widget.monthName}_${widget.dayNumber}"; // Unique key for each day in the month // Unique key for each day

  String?
      _newTaskContent; //This temporarily holds the content of a new task being created.
  _HomePageState(); //constructor for homepage
  @override
  Widget build(BuildContext context) {
    _deviceheight = MediaQuery.of(context).size.height;
    _devicewidth = MediaQuery.of(context).size.width;
    print("Input Value :$_newTaskContent");
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: _deviceheight * 0.15,
        title: Text(
          "Tasks of ${widget.monthName} ${widget.dayNumber}",
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _taskView(),
      floatingActionButton: _addTaskButton(),
    );
  }

  Widget _taskView() {
    // hive open box is future func
    //we cant add async and await becuse its UI function
    //init dunc also wont work it throw errror
    // so fUTUREBUILDER is the solution
    //Hive.openBox("tasks");

    return FutureBuilder(
      //This method returns a FutureBuilder that opens a Hive box named "tasks".
      // It uses the Hive.openBox method which returns a future.
      //The FutureBuilder allows the UI to react appropriately while the future is being resolved.
      // If the box is successfully opened (_snapshot.hasData),
      //it stores the box reference in _box and displays the task list (_taskList()).
      //Otherwise, it shows a loading spinner (CircularProgressIndicator).
      future: Hive.openBox("tasks"),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        //has data should dtop glitching effect
        if (snapshot.hasData) {
          _box = snapshot.data;
          return _taskList();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _taskList() {
    //there we are gonna add some actual data to hive
    //creating object of Task
    // Task _newTask =
    //Task(content: "Go to Gym!", timestamp: DateTime.now(), done: false);
    //box can be null or not so using question markk ?
    // _box?.add(_newTask.toMap());

    // now we creating list
    List tasks = _box!.get(_dayKey, defaultValue: []).toList();
    //we first create listview then we romove it and
    //convert it into list view builder and in return
    //we pass ListTile
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        var task = Task.fromMap(tasks[index]);
        // Format the date to include the day.
        String formattedDate =
            DateFormat('EEEE, MMM d, y').format(task.timestamp);
        return Card(
            elevation: 4, // Add elevation for 3D effect
            margin: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 12), // Example: Monday, Aug 28, 2023
            child: ListTile(
              leading: Text(
                "${index + 1}.",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              //Displays the content of the task.
              title: Text(
                //now we changes this
                task.content,
                style: TextStyle(
                    fontSize: 18,
                    //if our task is done then no decoration
                    //but if our task is not done then then we have line through it
                    decoration: task.done ? TextDecoration.lineThrough : null),
              ),

              //chnage this too to task
              //Displays the timestamp of the task.
              subtitle: Text(
                formattedDate,
                style: const TextStyle(fontSize: 12),
              ),
              //Text(task.timestamp.toString()),
              //Displays a checkmark icon indicating whether the task is done.
              trailing: Icon(
                task.done
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank_outlined,
                color: Colors.red,
              ),
              onTap: () {
                //we will inverse it
                //if task is done then undone it if task
                //is not done then done it
                //like it shows tick mark etc
                //when we mark or unmark something it shows blinking
                //it will fix through future builder
                task.done = !task.done;
                tasks[index] = task.toMap();
                _box!.put(_dayKey, tasks); // Save updated task list
                //_box!.putAt(index, task.toMap());
                widget.onTaskChanged(); // Notify that tasks have changed
                setState(() {}); // Refresh the task list in HomePage
              },
              //Deletes the task from the Hive box.
              onLongPress: () {
                tasks.removeAt(index);
                _box!.put(_dayKey, tasks); // Update after deletion

                //when we delete something it shows blinking
                //it will fix through future builder
                // _box!.deleteAt(index);
                widget.onTaskChanged(); // Notify that tasks have changed
                setState(() {}); // Refresh the task list in HomePage
              },
            ));
      },
    );
  }

  Widget _addTaskButton() {
    return FloatingActionButton(
      onPressed: _displayTaskPopup,
      child: const Icon(
        Icons.add,
        color: Colors.red,
      ),
    );
  }

  void _displayTaskPopup() {
    // Show a dialog to input a new task
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Task!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _newTaskContent = value; // Update task content as typed
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Enter your task', // Placeholder text
                ),
              ),
              const SizedBox(height: 10), // Space between input and button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_newTaskContent != null &&
                          _newTaskContent!.isNotEmpty) {
                        var task = Task(
                          content: _newTaskContent!,
                          timestamp: DateTime.now(),
                          done: false,
                        );

                        List tasks =
                            _box!.get(_dayKey, defaultValue: []).toList();
                        tasks.add(task.toMap()); // Add new task to the list
                        _box!.put(
                            _dayKey, tasks); // Save updated task list to Hive

                        widget
                            .onTaskChanged(); // Notify that tasks have changed
                        setState(() {
                          _newTaskContent = null; // Reset input field
                          Navigator.pop(context); // Close the dialog
                        });
                      }
                    },
                    child: const Text('Submit'), // Submit button
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
