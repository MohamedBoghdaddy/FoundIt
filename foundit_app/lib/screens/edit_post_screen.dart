import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditPostScreen({super.key, required this.postId, required this.postData});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedLocation;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.postData['title']);
    _descController = TextEditingController(text: widget.postData['description']);
    _selectedLocation = widget.postData['location'];
    _selectedType = widget.postData['type'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'location': _selectedLocation,
      'type': _selectedType,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post updated successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) =>
                    val != null && val.isNotEmpty ? null : "Title is required",
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (val) =>
                    val != null && val.isNotEmpty ? null : "Description is required",
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(labelText: "Location"),
                items: const [
                  DropdownMenuItem(value: "B-Building", child: Text("B-Building")),
                  DropdownMenuItem(value: "C-Building", child: Text("C-Building")),
                  DropdownMenuItem(value: "S-Building", child: Text("S-Building")),
                  DropdownMenuItem(value: "E-Building", child: Text("E-Building")),
                ],
                onChanged: (val) => setState(() => _selectedLocation = val),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Type"),
                items: const [
                  DropdownMenuItem(value: "lost", child: Text("Lost")),
                  DropdownMenuItem(value: "found", child: Text("Found")),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePost,
                child: const Text("Save Changes"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
