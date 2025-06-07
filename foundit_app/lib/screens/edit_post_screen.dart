import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedLocation;
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _locations = [
    "B-Building",
    "C-Building",
    "S-Building",
    "E-Building",
  ];

  final List<String> _types = [
    "lost",
    "found",
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.postData['title']);
    _descController = TextEditingController(text: widget.postData['description']);

    _selectedLocation = _locations.contains(widget.postData['location'])
        ? widget.postData['location']
        : null;

    _selectedType = _types.contains(widget.postData['type'])
        ? widget.postData['type']
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'location': _selectedLocation,
      'type': _selectedType,
    });

    setState(() => _isLoading = false);

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
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text("Edit Post"),
        centerTitle: true,
        backgroundColor: const Color(0xFF3182bd),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : "Title is required",
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : "Description is required",
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Select a building"),
                    items: _locations.map((loc) {
                      return DropdownMenuItem(
                        value: loc,
                        child: Text(loc),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val),
                    validator: (val) => val == null ? "Select a location" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Select type"),
                    items: _types.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                    validator: (val) => val == null ? "Select a type" : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _updatePost,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Changes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
