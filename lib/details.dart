import 'package:flutter/material.dart';

class DetailsPage extends StatefulWidget {
  final String title;
  final String description;
  final DateTime? deadline;

  const DetailsPage({
    super.key,
    required this.title,
    required this.description,
    this.deadline,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDeadline;
  static const Color themeColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    _selectedDeadline = widget.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _saveChanges() {
    Navigator.pop(context, {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "deadline": _selectedDeadline,
    });
  }

  void _deleteTask() {
    Navigator.pop(context, {"delete": true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 55, 107, 84),
      appBar: AppBar(
        title: const Text("Task Details", style: TextStyle(color: themeColor)),
        iconTheme: const IconThemeData(color: themeColor),
        backgroundColor: const Color.fromARGB(255, 1, 74, 33),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Color.fromARGB(255, 209, 147, 142),
            ),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                color: const Color.fromARGB(50, 0, 0, 0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 13,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        hintText: "Title of the Task",
                        labelStyle: TextStyle(color: themeColor),
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 181, 181, 181),
                        ),
                      ),
                      style: TextStyle(color: themeColor),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "Description of the Task",
                        labelStyle: TextStyle(color: themeColor),
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 181, 181, 181),
                        ),
                      ),
                      style: TextStyle(color: themeColor),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? "No deadline selected"
                                : "Deadline: ${_selectedDeadline!.toLocal()}"
                                    .split(" ")[0],
                            style: TextStyle(color: themeColor),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickDeadline,
                          child: const Text("Pick Date"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
