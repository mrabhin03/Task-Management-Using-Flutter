import 'package:flutter/material.dart';
import 'details.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/taskControl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

int generateNotificationId(int taskId, int index) {
  return (taskId.hashCode + index) & 0x7FFFFFFF;
}

Future<void> scheduleTaskNotifications(TaskDetails task) async {
  final scheduledTime = tz.TZDateTime.now(
    tz.local,
  ).add(const Duration(minutes: 20));
  print("Time now ${tz.TZDateTime.now(tz.local)}");
  print("Test notification scheduled at $scheduledTime");

  if (await Permission.scheduleExactAlarm.isGranted) {
    print("Scheduling notification for $scheduledTime");
    int notifId = generateNotificationId(task.taskId, 0);
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        "Task Reminder",
        "${task.title} is due soon",
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Reminders for task deadlines',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("Scheduled notification successfully");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  } else {
    print("Exact alarm permission not granted, showing immediate notification");
    await flutterLocalNotificationsPlugin.show(
      100,
      "Task Reminder",
      "${task.title} is due soon",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Verify notifications immediately',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
  checkScheduledNotifications();
}

Future<void> checkScheduledNotifications() async {
  final List<PendingNotificationRequest> pendingNotifications =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();

  if (pendingNotifications.isEmpty) {
    print("No notifications scheduled");
  } else {
    print("Scheduled notifications:");
    for (var n in pendingNotifications) {
      print("ID: ${n.id}, Title: ${n.title}, Body: ${n.body}");
    }
  }
}

Future<void> cancelTaskNotifications(int taskId) async {
  for (int i = 0; i < 8; i++) {
    await flutterLocalNotificationsPlugin.cancel(
      generateNotificationId(taskId, i),
    );
  }
}

Future<void> rescheduleTaskNotifications(TaskDetails task) async {
  await cancelTaskNotifications(task.taskId);
  await scheduleTaskNotifications(task);
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
void myBackgroundNotificationHandler(NotificationResponse response) {
  print("Background notification clicked: ${response.id}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  final String localTz = await FlutterTimezone.getLocalTimezone();
  String safeTz = localTz == "Asia/Calcutta" ? "Asia/Kolkata" : localTz;
  tz.setLocalLocation(tz.getLocation(safeTz));

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("Notification clicked: ${response.id}");
    },
    onDidReceiveBackgroundNotificationResponse: myBackgroundNotificationHandler,
  );
  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  if (androidPlugin != null) {
    final granted = await androidPlugin.requestExactAlarmsPermission();
    if (granted == null) {
      print("⚠️ Exact alarm permission not available on this device/OS");
    } else if (granted) {
      print("✅ Exact alarm permission granted");
    } else {
      print("❌ Exact alarm permission denied");
    }
  }
  if (await Permission.notification.isDenied) {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      print("✅ Notification permission granted");
    } else {
      print("❌ Notification permission denied");
    }
  } else {
    print("✅ Notification permission already granted");
  }

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 40, 149, 113),
        ),
      ),
      home: const TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  String filter = "Not Finished";
  late Box tasksBox;
  List<TaskDetails> tasks = [];
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
          return TaskDetails.fromMap(map);
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
    List<TaskDetails> filteredTasks;
    if (filter == "Finished") {
      filteredTasks = tasks.where((t) => t.isFinished).toList();
    } else if (filter == "Not Finished") {
      filteredTasks = tasks.where((t) => !t.isFinished).toList();
    } else {
      filteredTasks = tasks;
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 58, 106, 85),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 74, 33),
        elevation: 0,
        title: const Text(
          "My Tasks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(255, 255, 255, 1),
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
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
              ? Center(
                child: Text(
                  (filter == "Finished")
                      ? "No tasks yet finished!"
                      : (filter == "Not Finished")
                      ? "There is no Unfinished Tasks!"
                      : "No tasks yet. Tap + to add one!",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 10,
                                ),
                              ),
                              if (!task.isFinished)
                                OutlinedButton(
                                  onPressed: () {
                                    cancelTaskNotifications(task.taskId);
                                    setState(() {
                                      task.isFinished = true;
                                    });
                                    saveTasks();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color.fromARGB(
                                      255,
                                      64,
                                      135,
                                      111,
                                    ),
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 65, 141, 116),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text("Finish"),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            task.description,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 10),

                          (!task.isFinished)
                              ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    "Deadline: ${task.deadline.toString().substring(0, 16)}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    "Finished",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                // checkScheduledNotifications();
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
                                    cancelTaskNotifications(task.taskId);
                                  } else {
                                    setState(() {
                                      task.title = result["title"];
                                      task.description = result["description"];
                                      task.deadline = result["deadline"];
                                    });
                                    rescheduleTaskNotifications(task);
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
        backgroundColor: const Color.fromARGB(255, 78, 166, 107),
        child: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
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
                borderRadius: BorderRadius.circular(20),
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
                              color: Color.fromARGB(255, 38, 112, 88),
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
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        descController.text.isNotEmpty &&
                        deadline != null) {
                      setState(() {
                        TaskDetails task = TaskDetails(
                          taskId: DateTime.now().millisecondsSinceEpoch,
                          title: titleController.text,
                          description: descController.text,
                          deadline: deadline!,
                        );
                        tasks.add(task);
                        scheduleTaskNotifications(task);
                      });
                      saveTasks();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 55, 125, 102),
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
