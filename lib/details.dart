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
      appBar: AppBar(
        title: const Text("Task Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDeadline == null
                        ? "No deadline selected"
                        : "Deadline: ${_selectedDeadline!.toLocal()}".split(
                          " ",
                        )[0],
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDeadline,
                  child: const Text("Pick Date"),
                ),
              ],
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
