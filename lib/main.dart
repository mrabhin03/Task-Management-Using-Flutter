import 'package:flutter/material.dart';
import 'details.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/taskControl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
  runApp(const MyTasksApp());
}

class MyTasksApp extends StatelessWidget {
  const MyTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Tasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C9A8B)),
      ),
      home: const TaskHomePage(),
    );
  }
}

class Task {
  String title;
  String description;
  DateTime deadline;
  bool isFinished;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    this.isFinished = false,
  });
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  String filter = "Not Finished";
  late Box tasksBox;
  List<TaskDetials> tasks = [];
  void initState() {
    super.initState();
    tasksBox = Hive.box('tasksBox');
    loadTasks();
  }

  void loadTasks() {
    final storedTasks = tasksBox.get('tasks', defaultValue: []);

    tasks =
        (storedTasks as List).map((t) {
          final map = Map<String, dynamic>.from(t as Map);
          return TaskDetials.fromMap(map);
        }).toList();

    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));

    setState(() {});
  }

  void saveTasks() {
    final taskMaps = tasks.map((t) => t.toMap()).toList();
    tasksBox.put('tasks', taskMaps);
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    List<TaskDetials> filteredTasks;
    if (filter == "Finished") {
      filteredTasks = tasks.where((t) => t.isFinished).toList();
    } else if (filter == "Not Finished") {
      filteredTasks = tasks.where((t) => !t.isFinished).toList();
    } else {
      filteredTasks = tasks;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Tasks",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: "All", child: Text("All")),
                  PopupMenuItem(value: "Finished", child: Text("Finished")),
                  PopupMenuItem(
                    value: "Not Finished",
                    child: Text("Not Finished"),
                  ),
                ],
          ),
        ],
      ),
      body:
          filteredTasks.isEmpty
              ? const Center(
                child: Text(
                  "No tasks yet. Tap + to add one!",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!task.isFinished)
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      task.isFinished = true;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6C9A8B),
                                    side: const BorderSide(
                                      color: Color(0xFF6C9A8B),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text("Finish"),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),

                          if (!task.isFinished)
                            Text(
                              "Deadline: ${task.deadline.toString().substring(0, 16)}",
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DetailsPage(
                                          title: task.title,
                                          description: task.description,
                                          deadline: task.deadline,
                                        ),
                                  ),
                                );

                                if (result != null) {
                                  if (result["delete"] == true) {
                                    setState(() {
                                      tasks.remove(task);
                                    });
                                  } else {
                                    setState(() {
                                      task.title = result["title"];
                                      task.description = result["description"];
                                      task.deadline = result["deadline"];
                                    });
                                  }
                                  saveTasks();
                                }
                              },
                              child: const Text("View More →"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF6C9A8B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Add Task"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deadline == null
                                  ? "No deadline chosen"
                                  : "Deadline: ${deadline.toString().substring(0, 16)}",
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6C9A8B),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    deadline = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        descController.text.isNotEmpty &&
                        deadline != null) {
                      setState(() {
                        tasks.add(
                          TaskDetials(
                            title: titleController.text,
                            description: descController.text,
                            deadline: deadline!,
                          ),
                        );
                      });
                      saveTasks();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C9A8B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
