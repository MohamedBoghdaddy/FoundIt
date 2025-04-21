// create_post_screen.dart

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
  final _descController = TextEditingController();

  String? _location;
  String? _type;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                      : const Center(child: Text("Tap to select image")),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(labelText: "Location"),
                items: const [
                  DropdownMenuItem(value: "S-Building", child: Text("S-Building")),
                  DropdownMenuItem(value: "B-Building", child: Text("B-Building")),
                  DropdownMenuItem(value: "E-Building", child: Text("E-Building")),
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
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final defaultImageUrl = _selectedImage != null
                      ? _selectedImage!.path
                      : 'https://picsum.photos/seed/defaultImage/600/300';

                  await FirebaseFirestore.instance.collection('posts').add({
                    'userId': user?.uid,
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'location': _location,
                    'type': _type,
                    'imageUrl': defaultImageUrl,
                    'timestamp': Timestamp.now(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post Created")),
                    );
                  }
                },
                child: const Text("Post"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
