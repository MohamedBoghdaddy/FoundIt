import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();

  String? _location;
  String? _type;
  XFile? _selectedImage;
  List<String> questions = [];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _addQuestion() {
    if (_questionController.text.isNotEmpty) {
      setState(() {
        questions.add(_questionController.text);
      });
      _questionController.clear();
    }
  }

  Future<void> _savePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate()) return;

    final defaultImageUrl = _selectedImage != null
        ? _selectedImage!.path
        : 'https://picsum.photos/seed/defaultImage/600/300';

    final questionnaireRef =
        await FirebaseFirestore.instance.collection('questionnaires').add({
      'questions': questions,
      'correctAnswers': List.filled(questions.length, ''),
      'foundDate': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user?.uid,
      'title': _titleController.text.trim(),
      'location': _location,
      'type': _type,
      'imageUrl': defaultImageUrl,
      'timestamp': Timestamp.now(),
      'questionnaireId': questionnaireRef.id,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Created")),
      );
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return const Center(child: Text("Tap to select image"));
    }
    return kIsWeb
        ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
        : Image.file(File(_selectedImage!.path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text("Create Post"),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImagePreview(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _location,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "main-Building", child: Text("main-Building")),
                      DropdownMenuItem(value: "S-Building", child: Text("S-Building")),
                      DropdownMenuItem(value: "N-Building", child: Text("N-Building")),
                    ],
                    onChanged: (val) => setState(() => _location = val),
                    validator: (val) => val == null ? "Choose location" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "lost", child: Text("Lost")),
                      DropdownMenuItem(value: "found", child: Text("Found")),
                    ],
                    onChanged: (val) => setState(() => _type = val),
                    validator: (val) => val == null ? "Choose type" : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: "Enter Question",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Question"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6baed6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _savePost,
                    icon: const Icon(Icons.upload),
                    label: const Text("Post"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
