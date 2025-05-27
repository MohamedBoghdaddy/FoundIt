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

  BoxDecoration _gradientBackground() => const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: _gradientBackground(),
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: _selectedImage != null
                      ? (kIsWeb
                          ? Image.network(_selectedImage!.path,
                              fit: BoxFit.cover)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(File(_selectedImage!.path),
                                  fit: BoxFit.cover)))
                      : const Center(
                          child: Text("Tap to select image",
                              style: TextStyle(color: Colors.white))),
                ),
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(_titleController, "Title", true),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                  "Location",
                  _location,
                  [
                    "S-Building",
                    "B-Building",
                    "E-Building",
                  ],
                  (val) => setState(() => _location = val)),
              const SizedBox(height: 16),
              _buildStyledDropdown("Type", _type, ["lost", "found"],
                  (val) => setState(() => _type = val)),
              const SizedBox(height: 16),
              _buildStyledTextField(
                  _questionController, "Enter Question", false),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Question",
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              if (questions.isNotEmpty)
                Wrap(
                  children: questions
                      .map((q) => Chip(
                            label: Text(q,
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.purple[400],
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Post",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(
      TextEditingController controller, String label, bool required) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? "Required" : null
          : null,
    );
  }

  Widget _buildStyledDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownColor: Colors.purple[800],
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white,
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Required" : null,
    );
  }
}
