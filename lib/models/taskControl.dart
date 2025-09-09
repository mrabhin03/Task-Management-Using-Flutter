class TaskDetails {
  int taskId;
  String title;
  String description;
  DateTime deadline;
  bool isFinished;

  TaskDetails({
    required this.taskId,
    required this.title,
    required this.description,
    required this.deadline,
    this.isFinished = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'isFinished': isFinished,
    };
  }

  factory TaskDetails.fromMap(Map<String, dynamic> map) {
    return TaskDetails(
      taskId: map['taskId'] ?? DateTime.now().millisecondsSinceEpoch,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: DateTime.parse(map['deadline']),
      isFinished: map['isFinished'] ?? false,
    );
  }
}
