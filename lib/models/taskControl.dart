class TaskDetials {
  String title;
  String description;
  DateTime deadline;
  bool isFinished;

  TaskDetials({
    required this.title,
    required this.description,
    required this.deadline,
    this.isFinished = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'isFinished': isFinished,
    };
  }

  factory TaskDetials.fromMap(Map<String, dynamic> map) {
    return TaskDetials(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: DateTime.parse(map['deadline']),
      isFinished: map['isFinished'] ?? false,
    );
  }
}
