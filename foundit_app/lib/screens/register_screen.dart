import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String otp = '';

  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  bool otpSent = false;
  bool otpVerified = false;
  bool canResendOtp = true;

  Timer? countdownTimer;
  int countdownSeconds = 30;

  void startCountdown() {
    setState(() => canResendOtp = false);
    countdownSeconds = 30;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownSeconds > 0) {
          countdownSeconds--;
        } else {
          canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
        });
      } else {
        setState(() {
          _profileImageFile = File(image.path);
        });
      }
    }
  }

  Widget _buildProfileImage() {
    if (kIsWeb && _profileImageBytes != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: MemoryImage(_profileImageBytes!),
      );
    } else if (!kIsWeb && _profileImageFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_profileImageFile!),
      );
    } else {
      return const CircleAvatar(
        radius: 50,
        child: Icon(Icons.camera_alt, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text("Register"),
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
                    child: _buildProfileImage(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "First Name"),
                    validator: (val) =>
                        val != null && val.trim().isNotEmpty ? null : "Enter first name",
                    onChanged: (val) => firstName = val.trim(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Last Name"),
                    validator: (val) =>
                        val != null && val.trim().isNotEmpty ? null : "Enter last name",
                    onChanged: (val) => lastName = val.trim(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "MIU Email"),
                    validator: (val) =>
                        val != null && val.endsWith('@miuegypt.edu.eg')
                            ? null
                            : "Enter a valid MIU email",
                    onChanged: (val) => email = val.trim(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (val) => val != null && val.length >= 6
                        ? null
                        : "Password must be at least 6 characters",
                    onChanged: (val) => password = val.trim(),
                  ),
                  const SizedBox(height: 20),
                  if (otpSent)
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Enter OTP"),
                      onChanged: (val) => otp = val.trim(),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: canResendOtp
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await _authService.sendFirebaseOtp(email);
                                setState(() => otpSent = true);
                                startCountdown();

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("OTP sent to $email")),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error sending OTP: $e")),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3182bd),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      canResendOtp
                          ? "Send OTP"
                          : "Resend OTP in $countdownSeconds s",
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (otpSent && !otpVerified)
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final isValid = await _authService.verifyOtp(email, otp);
                          if (!isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid OTP")),
                            );
                            return;
                          }

                          setState(() => otpVerified = true);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("OTP Verified!")),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error verifying OTP: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6baed6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text("Verify OTP"),
                    ),
                  if (otpVerified)
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields")),
                          );
                          return;
                        }
                        try {
                          String? imageUrl;
                          if (!kIsWeb && _profileImageFile != null) {
                            imageUrl = await _authService.uploadProfileImage(
                              _profileImageFile!,
                              email,
                            );
                          } else if (kIsWeb && _profileImageBytes != null) {
                            imageUrl = await _authService.uploadProfileBytes(
                              _profileImageBytes!,
                              email,
                            );
                          }

                          await _authService.registerUser(
                            email,
                            password,
                            firstName,
                            lastName,
                            imageUrl: imageUrl,
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Registered Successfully")),
                          );

                          Navigator.pushReplacementNamed(context, '/home');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text("Register"),
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
