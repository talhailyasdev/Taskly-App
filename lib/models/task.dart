class Task {
  String content;
  DateTime timestamp;
  bool done;

  Task({required this.content, required this.timestamp, required this.done});

  // Factory method to create a Task from a Map
  factory Task.fromMap(Map task) {
    return Task(
      content: task['content'],
      // Convert the stored timestamp back into a DateTime object
      timestamp: DateTime.parse(task['timestamp']),
      done: task['done'],
    );
  }

  // Convert a Task into a Map to store in Hive
  Map<String, dynamic> toMap() {
    return {
      "content": content,
      // Convert DateTime into a string for storage
      "timestamp": timestamp.toIso8601String(),
      "done": done,
    };
  }
}

// }
// void main() {
//   // Create a Task object using the constructor
//   Task task = Task(content: "Finish project", timestamp: DateTime.now(), done: false);

//   // Convert the Task object to a Map
//   Map taskMap = task.toMap();
//   print(taskMap);

//   // Create a Task object from a Map using the factory constructor
//   Task newTask = Task.fromMap(taskMap);
//   print(newTask.content);

