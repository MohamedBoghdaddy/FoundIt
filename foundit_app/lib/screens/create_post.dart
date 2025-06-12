import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final String _backendUrl = kIsWeb
      ? "http://localhost:8000"
      : "http://10.0.2.2:8000"; // For Android emulator

  String? _location;
  String? _type;
  XFile? _selectedImage;
  List<String> generatedQuestions = [];
  Map<String, TextEditingController> answerControllers = {};
  String? _itemId;
  String? _imageUrlFromBackend;
  bool _isGeneratingQuestions = false;
  bool _isSavingAnswers = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        generatedQuestions = [];
        answerControllers.clear();
        _itemId = null;
        _imageUrlFromBackend = null;
      });
    }
  }

  Future<void> _generateQuestions() async {
    if (_selectedImage == null) return;

    setState(() => _isGeneratingQuestions = true);

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/gemini/analyze'),
      );

      if (kIsWeb) {
        // Web-safe: Use fromBytes
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _selectedImage!.name,
        ));
      } else {
        // Mobile-safe: Use fromPath
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ));
      }

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);

        setState(() {
          _itemId = jsonData['item_id'];
          generatedQuestions = List<String>.from(jsonData['questions']);
          _imageUrlFromBackend = jsonData['image_url'];

          // Initialize answer controllers
          for (int i = 0; i < generatedQuestions.length; i++) {
            answerControllers[i.toString()] = TextEditingController();
          }
        });
      } else {
        _showError('Failed to generate questions: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingQuestions = false);
    }
  }

  Future<void> _saveCorrectAnswers() async {
    if (_itemId == null || answerControllers.isEmpty) return;

    setState(() => _isSavingAnswers = true);

    try {
      // Prepare answers payload
      final answers = {
        for (int i = 0; i < generatedQuestions.length; i++)
          generatedQuestions[i]: answerControllers[i.toString()]?.text ?? ''
      };

      // Send to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/gemini/answer-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': _itemId,
          'answers': answers,
          'finder_id': FirebaseAuth.instance.currentUser?.uid,
        }),
      );

      if (response.statusCode == 200) {
        await _savePostToFirestore();
      } else {
        _showError('Failed to save answers: ${response.body}');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isSavingAnswers = false);
    }
  }

  Future<void> _savePostToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate() || _itemId == null) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user?.uid,
      'title': _titleController.text.trim(),
      'location': _location,
      'type': _type,
      'imageUrl': _imageUrlFromBackend,
      'timestamp': Timestamp.now(),
      'item_id': _itemId, // Reference to backend item
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Post Created Successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BoxDecoration _gradientBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C4DA1),
            Color(0xFF1C5DB1),
            Color(0xFF2979D1),
            Color(0xFF4090E3),
          ],
        ),
      );

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Center(
        child: Text(
          "Tap to select image",
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
      );
    }

    final imageWidget = kIsWeb
        ? Image.network(_selectedImage!.path, fit: BoxFit.contain)
        : Image.file(File(_selectedImage!.path), fit: BoxFit.contain);

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 0.5,
      maxScale: 3.0,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Create Post", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: _gradientBackground(),
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image picker section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImagePreview(),
                  ),
                ),
              ),

              // Generate questions button
              if (_selectedImage != null && generatedQuestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed:
                        _isGeneratingQuestions ? null : _generateQuestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C4DA1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isGeneratingQuestions
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Generate Verification Questions",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

              const SizedBox(height: 16),
              _buildStyledTextField(_titleController, "Title", true),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                "Location",
                _location,
                ["S-Building", "B-Building", "E-Building"],
                (val) => setState(() => _location = val),
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                "Type",
                _type,
                ["lost", "found"],
                (val) => setState(() => _type = val),
              ),

              // Generated questions section
              if (generatedQuestions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Verification Questions:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...generatedQuestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1}. $question",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: answerControllers[index.toString()],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Correct answer",
                                labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),

              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: (_isSavingAnswers || generatedQuestions.isEmpty)
                    ? null
                    : _saveCorrectAnswers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C4DA1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSavingAnswers
                    ? const CircularProgressIndicator(color: Color(0xFF0C4DA1))
                    : const Text(
                        "Create Post",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
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
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      dropdownColor: const Color(0xFF1C5DB1),
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
