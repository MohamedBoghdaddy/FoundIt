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
  List<String> questions = []; // Store the dynamic list of questions

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  // Add question to the list
  void _addQuestion() {
    if (_questionController.text.isNotEmpty) {
      setState(() {
        questions.add(_questionController.text);
      });
      _questionController.clear();
    }
  }

  // Save post and questionnaire to Firestore
  Future<void> _savePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate()) return;

    final defaultImageUrl = _selectedImage != null
        ? _selectedImage!.path
        : 'https://picsum.photos/seed/defaultImage/600/300';

    // Create a questionnaire associated with the post
    final questionnaireRef =
        await FirebaseFirestore.instance.collection('questionnaires').add({
      'questions': questions, // Add the list of questions here
      'correctAnswers': List.filled(
          questions.length, ''), // Empty for now, can be updated later
      'foundDate': Timestamp.now(),
    });

    // Add the post to Firestore
    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user?.uid,
      'title': _titleController.text.trim(),
      'location': _location,
      'type': _type,
      'imageUrl': defaultImageUrl,
      'timestamp': Timestamp.now(),
      'questionnaireId':
          questionnaireRef.id, // Link the post to the questionnaire
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Created")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: _selectedImage != null
                      ? (kIsWeb
                          ? Image.network(_selectedImage!.path,
                              fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path),
                              fit: BoxFit.cover))
                      : const Center(child: Text("Tap to select image")),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(labelText: "Location"),
                items: const [
                  DropdownMenuItem(
                      value: "main-Building", child: Text("S-Building")),
                  DropdownMenuItem(
                      value: "S-Building", child: Text("B-Building")),
                  DropdownMenuItem(
                      value: "N-Building", child: Text("E-Building")),
                ],
                onChanged: (val) => setState(() => _location = val),
                validator: (val) => val == null ? "Choose location" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: "Type"),
                items: const [
                  DropdownMenuItem(value: "lost", child: Text("Lost")),
                  DropdownMenuItem(value: "found", child: Text("Found")),
                ],
                onChanged: (val) => setState(() => _type = val),
                validator: (val) => val == null ? "Choose type" : null,
              ),
              const SizedBox(height: 20),
              // Add Question Section
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: "Enter Question"),
              ),
              ElevatedButton(
                onPressed: _addQuestion,
                child: const Text("Add Question"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePost,
                child: const Text("Post"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
